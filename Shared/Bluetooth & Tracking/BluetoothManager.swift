//
//  BluetoothManager.swift
//  AirGuard
//
//  Created by Leon Böttger on 15.04.22.
//

import CoreBluetooth
import SwiftUI
import CoreData


/// Wrapper class for CoreBluetooth actions
open class BluetoothManager: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate, ObservableObject {
    
    /// The initializer
    private override init() {
        super.init()
        
        if settings.tutorialCompleted {
            startCentralManager()
        }
    }
    
    /// The shared instance
    static var sharedInstance = BluetoothManager()
    
    /// The CoreBluetooth restore identifier
    private let restoreID = "airguard-bluetooth-manager"
    
    /// The requests queue
    private var requests = [BluetoothRequest]()

    /// The central manager
    var centralManager: CBCentralManager?
    
    /// Keeps a reference to all peripherals to keep receiving delegate calls - use `peripheralsSyncronizeDataQueue` to access
    private var peripherals: [String : BluetoothTempData] = [:]
    
    /// Shows if the manager is scanning
    @Published var scanning = false
    
    /// Shows if Bluetooth is turned on
    @Published var turnedOn = false
    
    /// True if the app is using fast scan with duplicates for precision finding
    @Published var isUsingFastScan = false
    
    /// Array of devices to which we can connect when using fast scan
    @Published var allowedConnectionUUIDsFastScan = [UUID]()
    
    /// The timer to turn on/off scanning periodically
    let timer = BluetoothManagerTimer.sharedInstance
    
    /// Reference to settings
    @ObservedObject var settings = Settings.sharedInstance

    /// Reference to notification manager
    @ObservedObject var notificationManager = NotificationManager.sharedInstance
    
    /// Determines if the Bluetooth Manager should only search for this given device.
    @Published var rssiScanForDevice: RSSIScan? = nil
    
    /// The serialized background queue of the bluetooth manager.
    private let bluetoothQueue = DispatchQueue(label: "bluetoothQueue")
    
    /// Background queue for access to `peripherals`
    let peripheralsSyncronizeDataQueue = DispatchQueue(label: "peripheralsSyncronizeDataQueue")
    
    
    /// Initializes the central manager.
    func startCentralManager() {
        
        bluetoothQueue.async { [self] in
            
            if(centralManager == nil) {
                
                let manager = CBCentralManager(delegate: self, queue: bluetoothQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: restoreID])
                self.centralManager = manager
                self.centralManagerDidUpdateState(manager)
            }
        }
    }
    
    
    /// Returns (and creates) the temporary Bluetooth data for the specified Bluetooth UUID.
    func getBluetoothData(bluetoothID: String) -> BluetoothTempData {
        
        return peripheralsSyncronizeDataQueue.sync {
            if let data = peripherals[bluetoothID] {
                return data
            }
            
            peripherals[bluetoothID] = BluetoothTempData(identifier: bluetoothID)
            
            return peripherals[bluetoothID]!
        }
    }
    
    
    /// Stores the data of a CBPeripheral in a BluetoothTempData object and returns it.
    private func storePeripheral(peripheral: CBPeripheral) -> BluetoothTempData {
       
        return peripheralsSyncronizeDataQueue.sync {
            let identifier = peripheral.identifier.uuidString
            
            if peripherals[identifier] == nil {
                peripherals[identifier] = BluetoothTempData(identifier: identifier)
            }
            
            if peripherals[identifier]!.peripheral_background != peripheral {
                peripherals[identifier]!.peripheral_background = peripheral
                peripheral.delegate = self
            }

            return peripherals[identifier]!
        }
    }

    
    /// Adds a bluetooth request to the queue. -- This needs to run on MAIN thread!
    func addRequest(request: BluetoothRequest) {
        
        bluetoothQueue.async { [self] in
            
            if !turnedOn {
                finishRequest(request: request, withState: .Timeout, peripheral: nil)
                return
            }
            
            // retrieve the peripheral
            if let id = UUID(uuidString: request.deviceID), let peripheral = centralManager?.retrievePeripherals(withIdentifiers: [id]).first {
                
                // add to queue
                requests.append(request)
                
                // add delegate
                let device = storePeripheral(peripheral: peripheral)
                
                // already connected
                if device.connected_background, let centralManager = centralManager {
                    self.centralManager(centralManager, didConnect: peripheral)
                }
                else {
                    if isUsingFastScan {
                        // Check if the we are allowed to connect to this device
                        if !allowedConnectionUUIDsFastScan.contains(peripheral.identifier) {
                            request.callback(.Failure, nil)
                            return
                        }
                    }
                    // connect to peripheral
                    centralManager?.connect(peripheral)
                }
            }
            
            // we did not find the peripheral
            else {
                request.callback(.Failure, nil)
            }
            
            // After 30 seconds, we send a timeout to the callback
            bluetoothQueue.asyncAfter(deadline: .now() + 30, execute: { [self] in
                if(requests.contains(where: { $0.id == request.id })) {
                    finishRequest(request: request, withState: .Timeout, peripheral: nil)
                }
            })
        }
    }
    
    
    /// Called if state of the central manager changed.
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        // Bluetooth is turned off
        if(!isSimulator() && central.state != CBManagerState.poweredOn) {
            notificationManager.sendManagerStoppedNotification()
            
            DispatchQueue.main.async {
                withAnimation {
                    self.turnedOn = false
                }
            }
           
            stopScan()
        }
        
        // Bluetooth is turned on
        else {
            DispatchQueue.main.async {
                withAnimation {
                    self.turnedOn = true
                }
            }
            
            notificationManager.removeManagerStoppedNotification()
            
            log("Manager started. Stopped notification id: \(notificationManager.stoppedNotificationID?.description ?? "???")")
            
            if(!scanning && settings.tutorialCompleted) {
                startScan()
            }
        }
    }
    
    
    /// Cancels all connections to peripherals.
    func cancelAllConnections() {
        
        if turnedOn {
            log("Cancelling All Connections...")
            
            // disconnect from everything
            peripheralsSyncronizeDataQueue.sync {
                for device in peripherals.values {
                    if let peripheral = device.peripheral_background {
                        centralManager?.cancelPeripheralConnection(peripheral)
                    }
                }
            }
        }
    }
    
    
    /// Starts a scan. Also stops the current scan and switches to the correct scan (background, foreground).
    func startScan(duplicates: Bool = false, services: [CBUUID]? = nil) {
        
        bluetoothQueue.async { [self] in
            
            if(turnedOn) {
                
                self.centralManager?.stopScan()
                
                let uuids = DeviceType.allCases.filter({$0.constants.supportsBackgroundScanning}).map({CBUUID(string: $0.constants.offeredService!)})
                
                if(settings.isBackground) {
                    
                    cancelAllConnections()
                    
                    if(settings.backgroundScanning) {
                        log("starting background scan...")
                        
                        /// CBCentralManagerScanOptionAllowDuplicatesKey is ignored in background scans: https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html
                        /// Multiple discovery events are coalesced into one
                        /// It is therefore not possible to detect if the Chipolo (without Find My) tracker is following us. 
                        self.centralManager?.scanForPeripherals(withServices: uuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
                    }
                }
                else {
                    log("starting foreground scan...")
                    if duplicates {
                        // When using fast scan we don't want connections in the background
                        cancelAllConnections()
                    }
                    self.centralManager?.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey : duplicates])
                }
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.scanning = true
                    }
                }
            }
        }
    }
    
    
    /// Stops the current scan.
    func stopScan() {
        
        bluetoothQueue.async { [self] in
            if(scanning) {
                log("stopping scan...")
                self.centralManager?.stopScan()
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.scanning = false
                    }
                }
            }
        }
    }
    
    
    /// Resets the Bluetooth manager.
    func reset() {
        bluetoothQueue.async { [self] in
            stopScan()
            
            cancelAllConnections()
            
            requests.removeAll()
            
            peripheralsSyncronizeDataQueue.sync {
                peripherals.removeAll()
            }
            
            startScan()
        }
    }
    
    
    /// Enables the fast scan which allowed advertisement duplicates. For better performance, you need to specify a Bluetooth device UUID or a service to search for. The service needs to be included in all advertisement packets.
    func enableFastScan(for device: RSSIScan, allowedUUIDs: [UUID]) {
        bluetoothQueue.async { [self] in
            
            DispatchQueue.main.async { [self] in
                allowedConnectionUUIDsFastScan = allowedUUIDs
                isUsingFastScan = true
                rssiScanForDevice = device
                
                if let service = device.service {
                    log("Fast Scan active for service \(service)")
                    startScan(duplicates: true, services: [CBUUID(string: service)])
                }
                if let id = device.bluetoothDevice {
                    log("Fast Scan active for device \(id)")
                    startScan(duplicates: true)
                }
            }
        }
    }
    
    
    /// Disables the fast scan which allowed advertisement duplicates.
    func disableFastScan() {
        bluetoothQueue.async { [self] in
            log("Fast Scan disabled")
            
            DispatchQueue.main.async { [self] in
                rssiScanForDevice = nil
                isUsingFastScan = false
                allowedConnectionUUIDsFastScan = []
                startScan()
            }
        }
    }
    
    
    /// Returns if the manager is currently only scanning for one device (type)
    func isFastScanning() -> Bool {
        return rssiScanForDevice != nil
    }
    
    
    /// Called if state of central manager is restored.
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
        if let devices = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            
            log("Restoring \(devices.count) devices")

            bluetoothQueue.async {
                for device in devices {
                    
                    let bluetoothData = self.storePeripheral(peripheral: device)
                    
                    PersistenceController.sharedInstance.modifyDatabaseBackground { context in
                        // re-add reference to peripheral
                        if fetchDeviceWithBluetoothID(uuid: bluetoothData.identifier_background, context: context) == nil {
                            addNewPeripheral(bluetoothData: bluetoothData, context: context)
                        }
                    }
                }
            }
            
            centralManagerDidUpdateState(central)
        }
    }


    /// Found new device via scan
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let id = rssiScanForDevice?.bluetoothDevice, peripheral.identifier.uuidString != id {
            return
        }
        
        // first, add peripheral to array
        let device = self.storePeripheral(peripheral: peripheral)
        
        device.rssi_background = Double(truncating: RSSI)
        
        if(!advertisementData.isEmpty) {
            device.advertisementData_background = advertisementData
        }
        
        discoveredDevice(bluetoothData: device)
    }
    
    
    /// Connected successfully to device
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        let device = storePeripheral(peripheral: peripheral)
        
        device.connected_background = true
        
        connectedToDevice(bluetoothData: device)
        
        for request in requests {
            if(request.deviceID == peripheral.identifier.uuidString) {
                
                // we are done with the request
                if(request.operation == .ProbeConnect) {
                    finishRequest(request: request, withState: .Success, peripheral: peripheral)
                }
                else {
                    if let service = request.serviceID {
                        //log("Discovering services of \(peripheral.identifier.description)...")
                        if let services = peripheral.services, services.contains(where: {$0.uuid.uuidString == service}) {
                            discoveredServices(peripheral: peripheral)
                        }else {
                            peripheral.discoverServices([CBUUID(string: service)])
                        }
                    }
                }
            }
        }
    }
    
    
    /// Refreshed RSSI of device
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let cm = centralManager {
            centralManager(cm, didDiscover: peripheral, advertisementData: [:], rssi: RSSI)
        }
    }
    
    
    /// Disconnected from device
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        let device = storePeripheral(peripheral: peripheral)
        
        device.connected_background = false
        
        // If we still have a request for this device, try to reconnect
        if(peripheralIsRequested(peripheral: peripheral)) {
            //log("Reconnecting to \(peripheral.identifier.description)...")
            centralManager?.connect(peripheral)
        }
    }
    
    
    /// Discovered services of device
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        discoveredServices(peripheral: peripheral)
    }
    
    
    /// Modified services of device
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        discoveredServices(peripheral: peripheral)
    }
    
    
    /// Handles requests when manager discovered services
    private func discoveredServices(peripheral: CBPeripheral) {
        for request in requests {
            if(request.deviceID == peripheral.identifier.uuidString) {
                
                if let service = peripheral.services?.first(where: {$0.uuid.uuidString == request.serviceID}) {
                 
                    if(request.operation == .ProbeService) {
                        finishRequest(request: request, withState: .Success, peripheral: peripheral)
                    }
                    else if let characteristic = request.characteristicID {
                        peripheral.discoverCharacteristics([CBUUID(string: characteristic)], for: service)
                    }
                    else {
                        finishRequest(request: request, withState: .Failure, peripheral: peripheral)
                    }
                }
            }
        }
    }
    
    
    /// Discoverered characteristics of service
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for request in requests {
            if(request.deviceID == peripheral.identifier.uuidString) {
                
                if let characteristic = service.characteristics?.first(where: {$0.uuid.uuidString == request.characteristicID}) {
                 
                    // we want to be notified if red/write operation was successful
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                    // read data
                    if(request.operation == .ReadCharacteristic) {
                        //log("Reading characteristic of \(peripheral.identifier.description)...")
                        peripheral.readValue(for: characteristic)
                    }
                    
                    // write data
                    if let data = request.data, request.operation == .WriteCharacteristic {
                        //log("Writing characteristic of \(peripheral.identifier.description)...")
                        peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        
                        // If write request is not acknowleged after one second, we assume that it was unsuccessful
                        bluetoothQueue.asyncAfter(deadline: .now() + 1, execute: { [self] in
                            if(requests.contains(where: {$0.id == request.id})) {
                                finishRequest(request: request, withState: .Failure, peripheral: peripheral)
                            }
                        })
                    }
                }
            }
        }
    }
    
    
    /// Called if characteristic written
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        for request in requests {
            if(request.deviceID == peripheral.identifier.uuidString && request.characteristicID == characteristic.uuid.uuidString && request.operation == .WriteCharacteristic) {
                
                log("Wrote characteristic!")
                
                if let error = error {
                    log(error.localizedDescription)
                    finishRequest(request: request, withState: .Failure, peripheral: peripheral)
                }
                else {
                    finishRequest(request: request, withState: .Success, peripheral: peripheral)
                }
            }
        }
    }
    
    
    /// Called if read value of characteristic
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        for request in requests {
            if(request.deviceID == peripheral.identifier.uuidString && request.characteristicID == characteristic.uuid.uuidString && request.operation == .ReadCharacteristic) {
                
                log("Read characteristic!")
                
                if let error = error {
                    log(error.localizedDescription)
                    finishRequest(request: request, withState: .Failure, peripheral: peripheral)
                }
                else {
                    finishRequest(request: request, withState: .Success, data: characteristic.value, peripheral: peripheral)
                }
            }
        }
    }
    
    
    /// Performs the callback of the request and deletes it
    private func finishRequest(request: BluetoothRequest, withState: BluetoothRequestState, data: Data? = nil, peripheral: CBPeripheral?) {

        request.callback(withState, data)
        
        requests.removeAll(where: {request.id == $0.id})
        
        if let peripheral = peripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    
    /// Returns true if there is a request for the given peripheral
    private func peripheralIsRequested(peripheral: CBPeripheral) -> Bool {
        return requests.contains(where: {$0.deviceID == peripheral.identifier.uuidString})
    }
}


/// Prints the name of the current thread/queue
func printCurrentQueueName() {
    let name = __dispatch_queue_get_label(nil)
    print("Current Queue: " + (String(cString: name, encoding: .utf8) ?? "Unknown Queue"))
}


/// Used to determine for what the Bluetooth Manager should search for. Only use `service` OR `bluetoothDevice`, not both.
struct RSSIScan {
    
    ///Bluetooth service to search for. The service needs to be included in all advertisement packets.
    var service: String?
    
    /// Bluetooth device UUID to search for.
    var bluetoothDevice: String?
}

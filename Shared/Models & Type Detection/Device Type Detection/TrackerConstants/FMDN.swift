//
//  Google.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 06.06.24.
//

import Foundation
import CoreData
import SwiftUI

final class GoogleConstants: TrackerConstants {
    override class var name: String { "google_find_my_device".localized() }
    
    override class var offeredService: String { "FEAA" }
    
    override class var supportsBackgroundScanning: Bool { true }
    
    override class var bestRSSI: Int { -32 }
    
    override class var supportsIgnore: Bool { false }
    
    override class var minMacAddressChangeTime: Int? { 24 }
    
    override class var canPlaySound: Bool { true }
    
    override class var soundService: String { "15190001-12F4-C226-88ED-2AC5579F2A85" }
    
    override class var soundCharacteristic: String? { "8E0C0001-1D68-FB92-BF61-48377421680E" }
    
    override class var soundStartCommand: String? { "0003" }
    
    override class var soundDuration: Int? { 10 }
    
    override class var supportsOwnerInfoOverBluetooth: Bool { true }
    
    override class var supportURL: String? {
        "https://www.android.com/learn-find-my-device/"
    }
    
    override class func iconView(trackerName: String) -> AnyView {
        trackerName.contains("Android") ? 
        AnyView(Circle()
            .modifier(TrackerIconView(imageName: getSmartphoneIcon()))) :
        AnyView(GoogleFindMyIcon())
    }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        detectTypeByNameOrAdvertisementData(baseDevice: baseDevice, deviceName: name, searchForService: offeredService) {
            
            setType(device: baseDevice, type: .Google, context: context)
            retrieveFMDNName(device: baseDevice, context: context)
        }
    }
    
    override class func discoveredAgain(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        
        // Try to retrieve name again
        retrieveFMDNName(device: baseDevice, context: context)
    }
    
    /// Extracts the connection status out of the advertisement data
    override class func connectionStatus(advertisementData: [String : Any]) -> ConnectionStatus {
        
        let servData = getServiceData(advertisementData: advertisementData, key: offeredService)
        
        if let servData = servData {
            
            // make array of characters
            let arr = Array(servData)
            
            // check if advertisement data has necessary length
            if arr.indices.contains(1) {
                
                let hex = String(arr[1])
                
                if let integer = Int(hex, radix: 16) {
                    var toBinary = Array(String(integer, radix: 2))
                    
                    // add zero padding
                    if toBinary.count < 4 {
                        toBinary = String(repeating: "0", count: max(0, 4 - toBinary.count)) + toBinary
                    }
                    
                    if toBinary.indices.contains(3) {
                        
                        let lastBit = toBinary[3] == "1"
                        
                        if lastBit {
                            return .OvermatureOffline
                        }
                        return .Connected
                    }
                }
            }
        }
        
        // No advertisement data
        return .Unknown
    }
    
    fileprivate static func getSmartphoneIcon() -> String {
        if #available(iOS 17.0, *) {
            return "smartphone"
        }
        return "candybarphone"
    }
}


/// Method to read the model name of Find My devices
fileprivate func retrieveFMDNName(device: BaseDevice, context: NSManagedObjectContext) {
    
    let bluetoothData = device.bluetoothTempData()
    let connectedToOwner = device.getType.constants.connectionStatus(advertisementData: bluetoothData.advertisementData_background) == .Connected
    
    // Only retrieve name in background if the device has seen for more than 30mins for power savings
    if let id = device.currentBluetoothId,
        device.name == nil,
        let firstSeen = device.firstSeen,
        !connectedToOwner,
        (!Settings.sharedInstance.isBackground ||
         (firstSeen.isOlderThan(seconds: minutesToSeconds(minutes: 30)))) {
        
        let objID = device.objectID
        
        let getModelNameOpcode: UInt16 = 0x0005
        var opcode = getModelNameOpcode.littleEndian
        let data = Data(bytes: &opcode, count: MemoryLayout.size(ofValue: opcode))
        
        // sound service and sound characteristic is also used for "info services", as required in the DULT standard
        let request = BluetoothRequest.writeReadCharacteristic(deviceID: id, serviceID: GoogleConstants.soundService, characteristicID: GoogleConstants.soundCharacteristic!, data: data) { state, data in
            
            if state == .Success, let data = data {
                
                // very important - we need to refetch device since we now are on a different context
                modifyDeviceOnBackgroundThread(objectID: objID) { context, device in
                    
                    let findMyName = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesNewlinesAndNulls)
                    
                    device.setName(name: findMyName)
                }
            }
        }
        
        BluetoothManager.sharedInstance.addRequest(request: request)
    }
    
    // Check if we have a smartphone
    if let id = device.currentBluetoothId,
       device.name == nil,
       connectedToOwner,
        !Settings.sharedInstance.isBackground {
        
        // Only available on smartphone
        let smartphoneService = "A3C87600-0005-1000-8000-001A11000100"
        
        let objID = device.objectID

        let request = BluetoothRequest.probeService(deviceID: id, serviceID: smartphoneService, callback: { state in
            
            // very important - we need to refetch device since we now are on a different context
            modifyDeviceOnBackgroundThread(objectID: objID) { context, device in
                
                if(state == .Success) {
                    device.setName(name: "offline_android_device".localized())
                }
                else {
                    // Not a smartphone => Set default name to avoid re-connection
                    device.setName(name: GoogleConstants.name)
                }
            }
        })
        
        BluetoothManager.sharedInstance.addRequest(request: request)
    }
}


struct GoogleFindMyIcon: View {
    
    var body: some View {
        
        ZStack {
            
            Circle()
            
            ZStack {
                Pie(start: 360 - 45 - 45, end: 45 - 45)
                    .foregroundColor(.white)
                
                Pie(start: 360 - 45 + 135, end: 45 + 135)
                    .foregroundColor(.white)
                
                Circle()
                    .foregroundColor(.airGuardBlue)
                    .padding(1.1)
                
                Circle()
                    .foregroundColor(.white)
                    .padding(7.5)
                
            }
            .padding(3)
        }
        .modifier(TrackerIconView(text: ""))
    }
}



struct Previews_GoogleFindMyDevice_Previews: PreviewProvider {
    static var previews: some View {
        GoogleConstants.iconView(trackerName: "")
    }
}

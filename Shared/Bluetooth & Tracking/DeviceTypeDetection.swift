//
//  DeviceTypeDetection.swift
//  AirGuard
//
//  Created by Leon Böttger on 19.06.22.
//

import Foundation
import CoreBluetooth
import CoreData


/// References to other objects
fileprivate let persistenceController = PersistenceController.sharedInstance
fileprivate let locationManager = LocationManager.sharedInstance
fileprivate let settings = Settings.sharedInstance
fileprivate let notificationManager = NotificationManager.sharedInstance
fileprivate let trackingDetection = TrackingDetection.sharedInstance
fileprivate let bluetoothManager = BluetoothManager.sharedInstance


/// Gets called if the BluetoothManager found a new device. Tries to determine the device type or update the existing device.
func discoveredDevice(bluetoothData: BluetoothTempData) {
    
    PersistenceController.sharedInstance.modifyDatabaseBackground { context in
        // got an update for existing device
        if let existing = fetchDeviceWithBluetoothID(uuid: bluetoothData.identifier_background, context: context) {
            
            updateExistingDevice(existing: existing, context: context)
            runDetections(bluetoothData: bluetoothData, baseDevice: existing, context: context)
        }
        else {
            
            // add a new device
            addNewPeripheral(bluetoothData: bluetoothData, context: context) { device in
                runDetections(bluetoothData: bluetoothData, baseDevice: device, context: context)
            }
        }
    }
}


/// Calls `detect` of all `TrackerConstants` to find out of which type the BaseDevice is.
func runDetections(bluetoothData: BluetoothTempData, baseDevice: BaseDevice, context: NSManagedObjectContext) {

    // not a tracker yet, not ignored and not currently connecting -> check it
    if(!baseDevice.isTracker && !baseDevice.ignore && !bluetoothData.connecting_background) {
        
        // these devices can be detected using the advertisement data.
        for elem in DeviceType.allCases.filter({$0.constants.supportsBackgroundScanning}) {
            elem.constants.detect(baseDevice: baseDevice, context: context)
        }
        
        // Still not detected, so try connecting
        if !baseDevice.isTracker {
            
            // monitor that we are now connecting
            bluetoothData.connecting_background = true
            
            // Try all types
            for elem in DeviceType.allCases.filter({!$0.constants.supportsBackgroundScanning}) {
                elem.constants.detect(baseDevice: baseDevice, context: context)
            }
        }
    }
}


/// Gets called if the BluetoothManager connected to a device successfully.
func connectedToDevice(bluetoothData: BluetoothTempData) {
    
    PersistenceController.sharedInstance.modifyDatabaseBackground { context in
        if let elem = fetchDeviceWithBluetoothID(uuid: bluetoothData.identifier_background, context: context) {

            elem.objectWillChange.send()
            elem.lastSeen = Date()
            
            if(elem.isTracker) {
                trackingDetection.addDetectionEvent(toDevice: elem, bluetoothData: bluetoothData, context: context)
            }
        }
    }
}


/// Gets called if a device was discovered by a scan, but is already present in the database.
func updateExistingDevice(existing: BaseDevice, context: NSManagedObjectContext) {
    
    existing.objectWillChange.send()
    existing.lastSeen = Date()
    
    if existing.isTracker, !existing.ignore {
        existing.getType.constants.discoveredAgain(baseDevice: existing, context: context)
        trackingDetection.addDetectionEvent(toDevice: existing, bluetoothData: existing.bluetoothTempData(), context: context)
    }
}


/// Adds a new device to the database with the given values.
func addNewPeripheral(bluetoothData: BluetoothTempData, context: NSManagedObjectContext, callback: (BaseDevice) -> () = {_ in }) {
    
    log("New Peripheral: \(String(describing: bluetoothData.peripheral_background?.name)) \(bluetoothData.identifier_background)")
    
    let newDevice = BaseDevice(context: context)
    let date = Date()
    
    newDevice.firstSeen = date
    newDevice.lastSeen = date
    newDevice.lastMacRenewal = date
    newDevice.uniqueId = bluetoothData.identifier_background
    newDevice.currentBluetoothId = bluetoothData.identifier_background
    
    // Very important: Pre-save now to make associate a fixed objectID with the BaseDevice
    PersistenceController.sharedInstance.sync(privateMOC: context)
    
    callback(newDevice)
}


/// Sets the type of a device
func setType(device: BaseDevice, type: DeviceType, withData: String? = nil, context: NSManagedObjectContext) {
    if(device.getType == .Unknown) {
        
        device.setType(type: type)
        device.ignore = false
        
        if let withData = withData {
            device.additionalData = withData
        }
        
        trackingDetection.addDetectionEvent(toDevice: device, bluetoothData: device.bluetoothTempData(), context: context)
        
        log("New \(type.rawValue) detected! (\(String(describing: device.currentBluetoothId?.description)))")
    }
}

//
//  MacDerandomizer.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 06.06.24.
//

import CoreData

/// Transfers the data (advertisement, last seen, rssi, detections ...) from the `new` device to the `existing` device
func transferTrackerData(existing: BaseDevice, new: BaseDevice, newEncryptionData: String? = nil, context: NSManagedObjectContext) {
    
    let tempData = existing.bluetoothTempData()
    
    tempData.connected_background = false
    
    if let newEncryptionData = newEncryptionData {
        existing.additionalData = newEncryptionData
    }
    
    existing.currentBluetoothId = new.currentBluetoothId
    
    updateExistingDevice(existing: existing, context: context)
    
    log("Updated \(existing.getName) \(existing.uniqueId ?? "?")")
}


/// Returns a Device discovered X minutes ago. Adds a buffer of +- 1 minute
func fetchPreviouslyDiscoveredDevices(minutesAgo minutes: Int, deviceType: DeviceType, withConnectionStatus connectionStatus: ConnectionStatus, context: NSManagedObjectContext) -> BaseDevice? {
    
    let xMin: Double = Double(-minutesToSeconds(minutes: minutes))
    let buffer: Double = minutesToSeconds(minutes: 1) // +- buffer
    
    let devices = fetchDevices(withPredicate: NSPredicate(
        format: "lastMacRenewal >= %@ && lastMacRenewal <= %@ && deviceType == %@",
        Date().addingTimeInterval(xMin - buffer) as CVarArg,
        Date().addingTimeInterval(xMin + buffer) as CVarArg,
        deviceType.rawValue
    ), context: context)
    
    // Only check for devices with the same connection status
    for device in devices {
        
        if let detections = device.detectionEvents?.array as? [DetectionEvent], let lastDetection = detections.last {
            
            if lastDetection.connectionStatus == connectionStatus.rawValue {
                
                // return the first one
                return device
            }
        }
    }
    
    return nil
}

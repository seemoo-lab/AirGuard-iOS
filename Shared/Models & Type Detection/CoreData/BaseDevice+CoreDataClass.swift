//
//  BaseDevice+CoreDataClass.swift
//  AirGuard
//
//  Created by Leon Böttger on 14.05.22.
//
//

import Foundation
import CoreData
import CoreBluetooth


@objc(BaseDevice)
public class BaseDevice: NSManagedObject {
    
    /// Returns temporary Bluetooth data associated with this device, such as RSSI.
    func bluetoothTempData() -> BluetoothTempData {
        return BluetoothManager.sharedInstance.getBluetoothData(bluetoothID: currentBluetoothId ?? "")
    }
}


/// Specifies if a device is not currently reachable.
func deviceNotCurrentlyReachable(device: BaseDevice, currentDate: Date, timeout: Int = Int(Constants.scanInterval*2)) -> Bool {
    
    // If device was not seen in the last X seconds, device is not reachable
    if let lastSeenSeconds = getLastSeenSeconds(device: device, currentDate: currentDate) {
        return lastSeenSeconds > timeout
    }
    
    return false
}


/// Returns nil if device has never been seen, and the duration in seconds until the device has been seen the last time.
func getLastSeenSeconds(device: BaseDevice, currentDate: Date) -> Int? {
    
    // was seen sometime
    if let lastSeen = device.lastSeen {
        return -Int(lastSeen.timeIntervalSince(currentDate))
    }
    
    // never seen
    return nil
}


/// Returns nil if device has never been seen, and the duration in seconds until the device has been seen the first time.
func getFirstSeenSeconds(device: BaseDevice, currentDate: Date) -> Int? {
    
    // was seen sometime
    if let firstSeen = device.firstSeen {
        return -Int(firstSeen.timeIntervalSince(currentDate))
    }
    
    // never seen
    return nil
}

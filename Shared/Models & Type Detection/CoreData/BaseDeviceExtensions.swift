//
//  BaseDeviceTypeExtensions.swift
//  AirGuard
//
//  Created by Leon Böttger on 09.06.22.
//

import Foundation
import CoreData
import CoreBluetooth


/// Class extensions of BaseDevice
extension BaseDevice  {
    
    /// Returns the name of the tracker.
    var getName: String {
        
        /// Device has a special name (e.g. Chipolo One Spot)
        if let name = name, name != "" {
            return name
        }
        
        /// Device has no name, return name of type
        return getType.constants.name
    }
    
    
    /// Sets the name of the tracker
    func setName(name: String) {
        self.name = name
    }
    
    
    /// Returns true if the device type is not set yet and it could be an AirTag or other Find My device
    var isMaybeAirtagOrFindMy: Bool {
        
        let data = bluetoothTempData()
        
        var connectable = false
        
        if let val = data.advertisementData_background[CBAdvertisementDataIsConnectable] as? Bool, val {
            connectable = true
        }

        
        return connectable && // device is connectable
        data.peripheral_background?.name == nil && // No name
        getType == .Unknown &&     // No Type
        data.advertisementData_background[CBAdvertisementDataServiceUUIDsKey] == nil && // No advertised services
        data.advertisementData_background[CBAdvertisementDataServiceDataKey] == nil &&
        data.advertisementData_background[CBAdvertisementDataManufacturerDataKey] == nil // No manufacturer data
    }
    
    
    /// Returns true if the device is a tracker.
    var isTracker: Bool {
        getType != .Unknown
    }
    
    
    /// Returns the type of the device.
    var getType: DeviceType {
        
        // A type is stored in the database
        if let deviceType = deviceType {
            return DeviceType(rawValue: deviceType) ?? .Unknown
        }
        
        // No type is stored
        return .Unknown
    }
    
    
    /// Sets the type of the device.
    func setType(type: DeviceType?) {
        if let type = type {
            deviceType = type.rawValue
        }
        else {
            deviceType = nil
        }
    }
}

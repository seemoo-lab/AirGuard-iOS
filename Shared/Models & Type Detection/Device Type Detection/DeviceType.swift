//
//  DeviceType.swift
//  AirGuard
//
//  Created by Leon Böttger on 18.04.22.
//

import Foundation
import CoreBluetooth
import SwiftUI

/// String appended to device type string for UserDefaults ignore key
private let ignoreString = "Ignore"


/// Enum storing all data and possible values of supported device types
enum DeviceType: String, CaseIterable, Identifiable {
    
    /// Identifier to support Identifiable protocol
    var id: String { self.rawValue }
    
    // Strings of types used in database for identification - DO NOT CHANGE
    case AirTag = "Apple AirTag"
    case FindMyDevice = "FindMy Device"
    case Tile = "Tile"
    case SmartTag = "Samsung SmartTag"
    /// Chipolo trackers without Find My that also work with Android
    case Chipolo = "Chipolo"
    case Google = "Google"
    case Unknown = "Unknown"

    /// Reference to class containing constants and functions of type.
    var constants: TrackerConstants.Type {
        switch self {
        case .AirTag:
            return AirTagConstants.self
        case .FindMyDevice:
            return FindMyDeviceConstants.self
        case .Tile:
            return TileConstants.self
        case .SmartTag:
            return SmartTagConstants.self
        case .Chipolo:
            return ChipoloConstants.self
        case .Google:
            return GoogleConstants.self
        case .Unknown:
            return TrackerConstants.self
        }
    }
    
    /// Sets the user defaults key to ignore the device for push notifications
    func setIgnore(toValue: Bool) {
        UserDefaults.standard.set(toValue, forKey: self.rawValue + ignoreString)
    }
    
    /// Returns if the device is ignored for push notifications
    func getIgnore() -> Bool {
        UserDefaults.standard.bool(forKey: self.rawValue + ignoreString)
    }
}

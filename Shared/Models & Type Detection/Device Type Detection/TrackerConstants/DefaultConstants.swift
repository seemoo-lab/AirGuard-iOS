//
//  DefaultConstants.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 06.06.22.
//

import SwiftUI
import CoreData

/// Base class of tracker constants. Filled with default implementation.
class TrackerConstants {
    
    /// Name of the device type, shown to user
    class var name: String { "unknown_device".localized() }
    
    /// A service which the tracker offers. If `supportsBackgroundScanning` is `false`, this service is not contained in the advertisement data. Can be used for identification.
    class var offeredService: String? { nil }
    
    /// Shows if the tracker can be found in the background. This implies that `alwaysAdvertisedService` is advertised even when the tracker is not connected.
    class var supportsBackgroundScanning: Bool { false }
    
    /// Service which is used for sound playback
    class var soundService: String? { nil }
    
    /// Characteristic which is used for sound playback
    class var soundCharacteristic: String? { nil }
    
    /// Start command which has to be sent to sound characteristic to start sound on tracker. Represented as Hex.
    class var soundStartCommand: String? { nil }
    
    class var canPlaySound: Bool { false }
    
    /// States in seconds how long a tracker plays a sound until it turns off automatically. Used for UI
    class var soundDuration: Int? { nil }
    
    /// Shows if the tracker has a build-in NFC tag to read out more information about the owner. Currently only supported by AirTag.
    class var supportsOwnerInfoOverNFC: Bool { false }
    
    /// Shows if the tracker supports provinding more information about the owner over Bluetooth. Currently only supported by Google FMDN devices.
    class var supportsOwnerInfoOverBluetooth: Bool { false }
    
    /// Shows if the tracker supports the ignore function. This means the tracker never changes its MAC address
    class var supportsIgnore: Bool { false }
    
    /// Support URL of the tracker users can use to find more information about it
    class var supportURL: String? { nil }
    
    /// RSSI value when the tracker is 10cm from phone
    class var bestRSSI: Int { -50 }
    
    /// Specifies the minimum tracking time in seconds until a tracking notification is sent
    class var minTrackingTime: Double { TrackingDetection.minimumTrackingTime }
    
    /// Specifies the  interval at which the MAC address is at least changed for this tracker. Specified in hours. Nil for never. Is currently only used to display this to the user in the UI.
    class var minMacAddressChangeTime: Int? { nil }
    
    /// Specifies the minimum distinct/clustered locations where a tracker should be found until a tracking notification is sent
    class var minDistinctLocations: Int {
        
        switch Settings.sharedInstance.securityLevel {
        case .Low:
            return 4
        case .Normal:
            return 3
        case .High:
            return 2
        }
    }
    
    /// Specifies how many seconds backwards tracking events are considered. By default this is 1 day.
    class var trackingEventsSince: TimeInterval {daysToSeconds(days: 1)}
    
    /// If false, the device type will be hidden from UI and be excluded from scanning.
    class var isEnabled: Bool { true }
    
    /// A SwiftUI view representing the tracker as small glyph. Used for manual scanning view.
    class func iconView(trackerName: String) -> AnyView {
        AnyView(Circle()
            .modifier(TrackerIconView()))
    }
    
    /// Function used to detect if the base device is of the type of the current class. If it is, the device type will be set.
    class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        
        // nothing to do here, since we are in the base class
    }
    
    /// Function used to signalize that the device was just seen again.
    class func discoveredAgain(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        
        // nothing to do here, since we are in the base class
    }
    
    /// Function used to determine if the tracker is connected to its owner. If it is, it can be ignored for background notifications.
    class func connectionStatus(advertisementData: [String : Any]) -> ConnectionStatus {
        return .Unknown
    }
}


/// Executes the callback if the baseDevice advertises the service specified with `searchFor` or the peripheral has the name `deviceName`
func detectTypeByNameOrAdvertisementData(baseDevice: BaseDevice, deviceName: String, searchForService: String, callback: () -> ()) {
   
    let tempData = baseDevice.bluetoothTempData()
    
    // check for name - might be faster than service check
    if tempData.peripheral_background?.name == deviceName {
        callback()
    }
    
    // fallback - check for services
    let services = getServiceDataKeys(advertisementData: tempData.advertisementData_background) + getServiceUUIDKeys(advertisementData: tempData.advertisementData_background)
    
    if(services.contains(searchForService)) {
        callback()
    }
}

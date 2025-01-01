//
//  SamsungFindMyMobile.swift
//  AirGuard
//
//  Created by Leon Böttger on 28.09.24.
//

import SwiftUI
import CoreData

final class FindMyMobileConstants: TrackerConstants {
    override class var name: String { "Samsung Find My Mobile" }
    
    override class var offeredService: String { "FD69" }
    
    override class var supportsBackgroundScanning: Bool { true }
    
    override class var bestRSSI: Int { -29 }
    
    override class var supportsIgnore: Bool { false }
    
    override class var supportURL: String? {
        "https://smartthingsfind.samsung.com/"
    }
    
    override class func iconView(trackerName: String) -> AnyView {
        AnyView (
            Circle()
                .scaleEffect(x: 1.1, y: 0.75, anchor: .center)
                .rotationEffect(Angle(degrees: -15))
                .padding(1)
                .modifier(TrackerIconView(text: "S"))
        )
    }
    
    override class var minMacAddressChangeTime: Int? { 24 }
    
    /// Since Chipolo trackers never change their MAC address we only consider tracking events for the last day
    override class var trackingEventsSince: TimeInterval {
        daysToSeconds(days: 1)
    }
    
    /// Find My Mobile trackers are mostly smartphones, and not that problematic when it comes to stalking. For power savings, they will be excluded in normal and low security level modes. For high security level, we allow them for scanning
    override class var isEnabled: Bool { Settings.sharedInstance.securityLevel == .High }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        detectTrackersBy15MinTechnique(baseDevice: baseDevice, context: context, nameForIdentification: name, trackerType: .FindMyMobile, encryptionDataStartByteInclusive: 1, encryptionDataEndByteExclusive: 13) {
            
            retrieveFindMyMobileName(device: baseDevice, context: context)
        }
    }
    
    override class func discoveredAgain(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        
        // Try to retrieve name again
        retrieveFindMyMobileName(device: baseDevice, context: context)
    }
    
    override class func connectionStatus(advertisementData: [String : Any]) -> ConnectionStatus {
        // They are always overmature offline, but since they do not change state we dont show any potential misleading information to the user
        return .Unknown
    }
}

/// Method to read the model name of Samsung Find My Mobile devices
fileprivate func retrieveFindMyMobileName(device: BaseDevice, context: NSManagedObjectContext) {
    
    // Only retrieve name in foreground for power savings
    // Name reading does not always succeed for Find My Mobile Devices
    // Therefore, we did disable it in background to avoid excessive re-connections
    if let id = device.currentBluetoothId,
        device.name == nil,
        !Settings.sharedInstance.isBackground {
        
        let objID = device.objectID
        
        let request = BluetoothRequest.readCharacteristic(deviceID: id, serviceID: "1800", characteristicID: "2A00") { state, data in
            
            if state == .Success, let data = data {
                
                // very important - we need to refetch device since we now are on a different context
                modifyDeviceOnBackgroundThread(objectID: objID) { context, device in
                    
                    let name = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesNewlinesAndNulls)
                    device.setName(name: name)
                }
            }
        }
        
        BluetoothManager.sharedInstance.addRequest(request: request)
    }
}


#Preview {
    FindMyMobileConstants.iconView(trackerName: "")
}

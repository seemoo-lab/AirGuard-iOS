//
//  AirTag.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 06.06.22.
//

import SwiftUI
import CoreData

final class AirTagConstants: TrackerConstants {
    
    override class var name: String { "Apple AirTag" }
    
    override class var offeredService: String { AirTagConstants.soundService }
    
    override class var soundService: String { "7DFC9000-7D1C-4951-86AA-8D9728F8D66C" }
    
    override class var soundCharacteristic: String? { "7DFC9001-7D1C-4951-86AA-8D9728F8D66C" }
    
    override class var soundStartCommand: String? { "AF" }
    
    override class var soundDuration: Int? { 15 }
    
    override class var supportsNFC: Bool { true }
    
    override class var bestRSSI: Int { -41 }
    
    override class var supportURL: String? { "https://support.apple.com/en-us/HT212227" }
    
    override class var iconView: AnyView {
        AnyView(Circle()
            .modifier(TrackerIconView(imageName: "applelogo")))
    }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        detectAirTagsAndFindMyDevices(baseDevice: baseDevice, detectService: offeredService, context: context) { baseDevice, context in
            setType(device: baseDevice, type: .AirTag, context: context)
        }
    }
    
    override class var canPlaySound: Bool { true }
}


/// Executes the callback if the baseDevice is an AirTag or Find My device
func detectAirTagsAndFindMyDevices(baseDevice: BaseDevice, detectService: String, context: NSManagedObjectContext, callback: @escaping (BaseDevice, NSManagedObjectContext) -> ()) {
    
    if baseDevice.isMaybeAirtagOrFindMy, let id = baseDevice.currentBluetoothId {
        
        let objID = baseDevice.objectID

        let request = BluetoothRequest.probeService(deviceID: id, serviceID: detectService, callback: { state in
            
            // very important - we need to refetch device since we now are on a different context
            modifyDeviceOnBackgroundThread(objectID: objID) { context, baseDevice in
                
                if(state == .Success) {
                    callback(baseDevice, context)
                }
                
                // the device is not an AirTag or Find My device or any other tracker, so ignore it in the future
                if state == .Failure, !baseDevice.isTracker {
                    baseDevice.ignore = true
                }
                
                let tempData = baseDevice.bluetoothTempData()
                
                tempData.connecting_background = false
            }
        })
        
        BluetoothManager.sharedInstance.addRequest(request: request)
    }
}

//
//  Pebblebee.swift
//  AirGuard
//
//  Created by Leon Böttger on 24.09.24.
//

import Foundation
import CoreData
import SwiftUI

final class PebblebeeConstants: TrackerConstants {
    override class var name: String { "pebblebee_without_findmy".localized() }
    
    override class var offeredService: String { "FA25" }
    
    override class var supportsBackgroundScanning: Bool { true }
    
    override class var canPlaySound: Bool { true }
    
    override class var soundService: String? { "0000FA25-0000-1000-8000-00805F9B34FB" }
    
    override class var soundCharacteristic: String? { "00002C02-0000-1000-8000-00805F9B34FB" }
    
    override class var soundStartCommand: String? { "01" }
    
    override class var soundDuration: Int? { 18 }
    
    override class var supportsIgnore: Bool { true }
    
    override class var supportURL: String? {
        "https://help.pebblebee.com/category/ikniigc1j2-pebblebee-products"
    }
    
    override class func iconView(trackerName: String) -> AnyView {
        AnyView (
            Circle()
                .padding(1)
                .modifier(TrackerIconView(text: "P"))
        )
    }
    
    /// Since Pebblebee trackers never change their MAC address we only consider tracking events for the last day
    override class var trackingEventsSince: TimeInterval {
        daysToSeconds(days: 1)
    }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        detectTypeByNameOrAdvertisementData(baseDevice: baseDevice, deviceName: "PB - ", searchForService: offeredService) {

            setType(device: baseDevice, type: .Pebblebee, context: context)
            retrievePebblebeeName(device: baseDevice, context: context)
        }
    }
    
    override class func discoveredAgain(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        
        // Try to retrieve name again
        retrievePebblebeeName(device: baseDevice, context: context)
    }
    
    override class func connectionStatus(advertisementData: [String : Any]) -> ConnectionStatus {
        return .Unknown
    }
}


/// Method to read the model name of Pebblebee devices
fileprivate func retrievePebblebeeName(device: BaseDevice, context: NSManagedObjectContext) {
    
    // Only retrieve name in background if the device has seen for more than 30mins for power savings
    if let id = device.currentBluetoothId,
        device.name == nil,
        let firstSeen = device.firstSeen,
        (!Settings.sharedInstance.isBackground ||
         (firstSeen.isOlderThan(seconds: minutesToSeconds(minutes: 30)))) {
        
        let objID = device.objectID
        
        let request = BluetoothRequest.readCharacteristic(deviceID: id, serviceID: "180A", characteristicID: "2A24") { state, data in
            
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

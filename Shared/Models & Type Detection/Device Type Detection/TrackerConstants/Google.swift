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
    override class var name: String { "Google Find My Device" }
    
    override class var offeredService: String { "FEAA" }
    
    override class var supportsBackgroundScanning: Bool {true}
    
    override class var bestRSSI: Int {-32}
    
    override class var supportsIgnore: Bool {false}
    
    override class var minMacAddressChangeTime: Int? { 24 }
    
    override class var canPlaySound: Bool { true }
    
    override class var soundService: String { "15190001-12F4-C226-88ED-2AC5579F2A85" }
    
    override class var soundCharacteristic: String? { "8E0C0001-1D68-FB92-BF61-48377421680E" }
    
    override class var soundStartCommand: String? { "0003" }
    
    override class var soundDuration: Int? { 10 }
    
    override class var iconView: AnyView {
        AnyView (
            Circle()
                .padding(1)
                .modifier(TrackerIconView(text: "G"))
        )
    }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        detectTypeByNameOrAdvertisementData(baseDevice: baseDevice, deviceName: name, searchForService: offeredService) {
            
//            // check if there is a Google Tracker discovered 15 minutes ago. Google Trackers change their mac address every 15 minutes, so we can port the old data to the "new" device
//            // we only take those Google Trackers 15m/30m ago which have the same connection status - this is another identifier we can use to minimize the risk of merging two different Google Trackers
//            
//            for minutes in [15, 30] {
//                if let existing = fetchPreviouslyDiscoveredDevices(minutesAgo: minutes, deviceType: .Google, withConnectionStatus: .Unknown, context: context) {
//                    
//                    log("Refreshing Google MAC... - \(minutes)m - \(baseDevice.uniqueId?.description ?? "?")")
//                    
//                    existing.lastMacRenewal = Date()
//                    
//                    transferTrackerData(existing: existing, new: baseDevice, context: context)
//                    
//                    return
//                }
//            }
            
            setType(device: baseDevice, type: .Google, context: context)
        }
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
}

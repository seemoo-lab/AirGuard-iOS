//
//  SmartTag.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 06.06.22.
//

import SwiftUI
import CoreData

final class SmartTagConstants: TrackerConstants {
    
    override class var name: String { "Samsung SmartTag" }
    
    override class var offeredService: String { "FD5A" }
    
    override class var supportsBackgroundScanning: Bool { true }
    
    override class var bestRSSI: Int { -31 }
    
    override class var minTrackingTime: Double {
        
        /// Reduced time required for tracking since the SmartTag is harder to identify over longer time
        if Settings.sharedInstance.securityLevel == .Low {
            return 80
        }
        return TrackingDetection.minimumTrackingTime
    }
    
    override class var supportURL: String? { "https://www.samsung.com/us/mobile/mobile-accessories/phones/samsung-galaxy-smart-tag-1-pack-black-ei-t5300bbegus/#benefits" }
    
    override class var minMacAddressChangeTime: Int? { 24 }
    
    override class var iconView: AnyView {
        AnyView(RoundedRectangle(cornerRadius: 5)
            .padding(2)
            .rotationEffect(Angle(degrees: 45))
            .modifier(TrackerIconView(text: "S")))
    }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        
        detectTypeByNameOrAdvertisementData(baseDevice: baseDevice, deviceName: "Smart Tag", searchForService: offeredService) {
            
            let advertisementData = baseDevice.bluetoothTempData().advertisementData_background
            
            // get the raw data for the SmartTag service
            let servData = getServiceData(advertisementData: advertisementData, key: SmartTagConstants.offeredService)
            let encryptionData = getEncryptionData(serviceData: servData ?? "")
            
            // get the current owner connection status
            let connectionStatus = connectionStatus(advertisementData: advertisementData)
            
            let time: Double
            
            // in this case, the encyrption key changes every 8h. Thus, we search for SmartTags with the same encryption key in the last 24 hours
            if connectionStatus == .OvermatureOffline {
                log("Detected SmartTag Disconnected More Than 8h.")
                time = -hoursToSeconds(hours: 8)
            }
            // in this case, the encyrption key changes every 15m. Thus, we search for SmartTags with the same encryption key in the last 15m
            else {
                log("Detected SmartTag Disconnected More Than 15m.")
                time = -minutesToSeconds(minutes: 15)
            }
            
            // get all SmartTags with same encryption key during last 15 minutes or 24 hours
            let sameEncryptionData = fetchDevices(withPredicate: NSPredicate(
                format: "lastSeen >= %@ && deviceType == %@ && additionalData == %@",
                Date().addingTimeInterval(time) as CVarArg,
                DeviceType.SmartTag.rawValue, encryptionData ?? "no key" // if encryptionData = nil, nothing will be returned
            ), context: context)
            
            
            // check if there is a SmartTag with identical encryption key. We then know that it's the same device, even though the mac address / uuid might be different
            if let existing = sameEncryptionData.first {
                
                log("Refreshed SmartTag MAC - Encryption Key (\(encryptionData ?? "?")) - \(baseDevice.uniqueId?.description ?? "?")")
                
                transferTrackerData(existing: existing, new: baseDevice, newEncryptionData: encryptionData, context: context)
                return
            }
            
            
            // check if there is a SmartTag discovered 15 minutes ago. SmartTags change their mac address every 15 minutes, so we can port the old data to the "new" device
            // we only take those SmartTags 15m/30m ago which have the same connection status - this is another identifier we can use to minimize the risk of merging two different SmartTags
            
            for minutes in [15, 30] {
                if let existing = fetchPreviouslyDiscoveredDevices(minutesAgo: minutes, deviceType: .SmartTag, withConnectionStatus: connectionStatus, context: context) {
                    
                    log("Refreshing SmartTag MAC... - \(minutes)m - \(baseDevice.uniqueId?.description ?? "?")")
                    
                    existing.lastMacRenewal = Date()
                    
                    transferTrackerData(existing: existing, new: baseDevice, newEncryptionData: encryptionData, context: context)
                    
                    return
                }
            }
            
            // This actually is a new SmartTag, no data transfer needed
            if connectionStatus == .PrematureOffline {
                
                // Due to the SmartTag architecture, we assume that the last MAC renewal happened the last quarter of the hour
                baseDevice.lastMacRenewal = baseDevice.firstSeen?.lastFifteenMinutes()
                log("Set SmartTag lastMacRenewal to \(String(describing: baseDevice.lastMacRenewal)) from \(String(describing: baseDevice.firstSeen))")
            }
            
            setType(device: baseDevice, type: .SmartTag, withData: encryptionData, context: context)
        }
    }
    
    
    /// Extracts the SmartTagConnectionStatus out of the advertisement data
    override class func connectionStatus(advertisementData: [String : Any]) -> ConnectionStatus {
        
        let servData = getServiceData(advertisementData: advertisementData, key: SmartTagConstants.offeredService)
        
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
                        
                        /// Determines if SmartTag is paired to other device
                        let bit5 = toBinary[1] == "1"
                        
                        /// 3rd bit of second byte (=6th bit counting from 0) determines if tracker was not connected to owner in last 15 minutes but less than 24 hours
                        let bit6 = toBinary[2] == "1"
                        
                        /// 4rd bit of second byte (=7th bit counting from 0) determines if tracker was not connected to owner for more than 24 hours
                        let bit7 = toBinary[3] == "1"
                        
                        if (!bit5 && bit6 && bit7) {
                            return .OvermatureOffline
                        } else if (!bit5 && bit6 && !bit7) {
                            return .Offline
                        } else if (!bit5 && !bit6 && bit7) {
                            return .PrematureOffline
                        } else {
                            return .Connected
                        }
                    }
                }
            }
        }
        
        // No advertisement data
        return .Unknown
    }
}


/// Extracts the encryption data from service data of a SmartTag
func getEncryptionData(serviceData: String) -> String? {
    
    // encryption key cannot be extracted
    if serviceData.count < 24 {
        return nil
    }
    
    // start of advertisement data
    let startIndex = serviceData.startIndex
    
    // encryption key begins after the 8th hex character
    let encryptionKeyStartIndex = serviceData.index(startIndex, offsetBy: 8)
    
    // encryption key has 64bit -> 64/4 = 16 hex characters. 16 + 8 = 24
    let encryptionKeyStopIndex = serviceData.index(startIndex, offsetBy: 24)
    
    // encryption key range
    let range = encryptionKeyStartIndex..<encryptionKeyStopIndex
    
    // substring
    let encryptionKey = serviceData[range]
    
    // return the substring as string
    return String(encryptionKey)
}

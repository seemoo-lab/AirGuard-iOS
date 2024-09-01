//
//  ChipoloConstants.self.swift
//  AirGuard
//
//  Created by Alex - SEEMOO on 13.02.23.
//

import Foundation
import CoreData
import SwiftUI

final class ChipoloConstants: TrackerConstants {
    override class var name: String { "chipolo_without_findmy".localized() }
    
    override class var offeredService: String { "FE33" }
    
    override class var supportsBackgroundScanning: Bool {true}
    
    override class var bestRSSI: Int {-29}
    
    override class var supportsIgnore: Bool {true}
    
    override class var supportURL: String? {
        "https://support.chipolo.net/hc/en-us/articles/6238525469969-How-to-disable-a-Chipolo-ONE-Spot-"
    }
    
    override class var iconView: AnyView {
        AnyView (
            Circle()
                .padding(1)
                .modifier(TrackerIconView(text: "C"))
        )
    }
    
    /// Since Chipolo trackers never change their MAC address we only consider tracking events for the last day
    override class var trackingEventsSince: TimeInterval {
        daysToSeconds(days: 1)
    }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        detectTypeByNameOrAdvertisementData(baseDevice: baseDevice, deviceName: "Chipolo", searchForService: offeredService) {
            setType(device: baseDevice, type: .Chipolo, context: context)
        }
    }
    
    override class func connectionStatus(advertisementData: [String : Any]) -> ConnectionStatus {
        return .Unknown
    }
}

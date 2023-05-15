//
//  Tile.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 06.06.22.
//

import SwiftUI
import CoreData

final class TileConstants: TrackerConstants {

    override class var name: String { "Tile" }
    
    override class var offeredService: String { "FEED" }
    
    override class var supportsBackgroundScanning: Bool { true }
    
    override class var supportsIgnore: Bool { true }
    
    override class var bestRSSI: Int { -39 }
    
    override class var supportURL: String? { "https://tileteam.zendesk.com/hc/en-us/articles/203954683-Return-a-Tile-to-Its-Owner" }
    
    override class var iconView: AnyView {
        AnyView(RoundedRectangle(cornerRadius: 5)
            .padding(1)
            .modifier(TrackerIconView(text: "tile")))
    }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
    
        detectTypeByNameOrAdvertisementData(baseDevice: baseDevice, deviceName: "Tile", searchForService: offeredService) {
            setType(device: baseDevice, type: .Tile, context: context)
        }
    }
}

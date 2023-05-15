//
//  TrackerDetailView.swift
//  AirGuard
//
//  Created by Leon Böttger on 03.05.22.
//

import SwiftUI
import CoreBluetooth
import MapKit


struct TrackerDetailView: View {
    
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var bluetoothData: BluetoothTempData
    @StateObject var soundManager = SoundManager()
    @ObservedObject var clock = Clock.sharedInstance
    
    let persistenceController = PersistenceController.sharedInstance
    
    var body: some View {
        
        // Calculated here for animation
        let notCurrentlyReachable = deviceNotCurrentlyReachable(device: tracker, currentDate: clock.currentDate)
        
        NavigationSubView(spacing: Constants.SettingsSectionSpacing) {
            
            DetailTopView(tracker: tracker, bluetoothData: bluetoothData, notCurrentlyReachable: notCurrentlyReachable)
            
            DetailMapView(tracker: tracker)
            
            DetailGeneralView(tracker: tracker, soundManager: soundManager)
            
            DetailNotificationsView(tracker: tracker)
            
            DetailMoreView(tracker: tracker)
            DetailDebugView(tracker: tracker, bluetoothData: bluetoothData)
        }
        .animation(.spring(), value: tracker.ignore)
        .animation(.spring(), value: notCurrentlyReachable)
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct Previews_TrackerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .Tile)
        device.firstSeen = Date()
        device.lastSeen = Date()
        
        let detectionEvent = DetectionEvent(context: vc)
        
        detectionEvent.time = device.lastSeen
        detectionEvent.baseDevice = device
        
        let location = Location(context: vc)
        
        location.latitude = 52
        location.longitude = 8
        location.accuracy = 1
        
        detectionEvent.location = location
        
        try? vc.save()
        
        return NavigationView {
            TrackerDetailView(tracker: device, bluetoothData: BluetoothTempData(identifier: UUID().uuidString))
                .environment(\.managedObjectContext, vc)
        }
    }
}

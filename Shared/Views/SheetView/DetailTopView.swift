//
//  DetailTopView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.08.22.
//

import SwiftUI

struct DetailTopView: View {
    
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var bluetoothData: BluetoothTempData
    @ObservedObject var clock = Clock.sharedInstance
    let notCurrentlyReachable: Bool
    
    var body: some View {
        
        VStack {
            HStack {
                Text(tracker.getName)
                    .bold()
                    .font(.largeTitle)
                    .lineLimit(1)
                    .foregroundColor(Color("DarkBlue"))

                Spacer()
                
            }
            .padding(.horizontal)
            .padding(.horizontal, 5)
            .padding(.bottom, 2)
            
            
            if let lastSeenSeconds = getLastSeenSeconds(device: tracker, currentDate: clock.currentDate) {
                
                let connectionStatus = tracker.getType.constants.connectionStatus(advertisementData: bluetoothData.advertisementData_publisher)
                
                VStack(spacing: 2) {
                    if notCurrentlyReachable {
                        Text("no_connection".localized())
                            .bold()
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    else {
                        if connectionStatus != .Unknown {
                            Text(connectionStatus.description.localized())
                                .bold()
                                .foregroundColor(connectionStatus == .OwnerDisconnected ? .red : connectionStatus == .OwnerConnected ? .green : formHeaderColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Text("last_seen".localized() + ": \(getSimpleSecondsText(seconds: lastSeenSeconds))")
                        .bold()
                        .foregroundColor(formHeaderColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                .padding(.horizontal, 5)
                .padding(.horizontal)
            }
        }
    }
}

struct Previews_TrackerTopView_Previews: PreviewProvider {
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

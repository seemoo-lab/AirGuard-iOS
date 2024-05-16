//
//  TrackerHistoryView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 10.07.22.
//

import SwiftUI

struct TrackerHistoryView: View {
    
    @ObservedObject var clock = Clock.sharedInstance
    
    // Show all devices EXCEPT those shown in manual scan
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BaseDevice.lastSeen, ascending: false)],
        predicate: NSPredicate(format: "lastSeen < %@ AND deviceType != %@ AND deviceType != nil", Clock.sharedInstance.currentDate.addingTimeInterval(-Constants.manualScanBufferTime) as CVarArg, DeviceType.Unknown.rawValue),
        animation: .spring())
    private var devices: FetchedResults<BaseDevice>
    
    var body: some View {
        
        ScrollView {
            LazyVStack {
                
                if(devices.count == 0) {
                    BigSymbolViewWithText(title: "", symbol: "questionmark", subtitle: "no_device_detected_yet")
                }
                else {
                    Text("tracker_history_hint")
                        .foregroundColor(.white)
                        .padding()
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                Color.airGuardBlue
                                LinearGradient(colors: [.clear, .white.opacity(0.2)], startPoint: .bottom, endPoint: .top)
                            }
                                .cornerRadius(25))
                    
                        .padding(.horizontal, 15)
                        .padding(.top)
                    
                    ForEach(devices) { elem in
                        
                        if let detectionEvents = elem.detectionEvents, let lastSeenSeconds = getLastSeenSeconds(device: elem, currentDate: clock.currentDate) {
                            
                            let times = detectionEvents.count
                            let timesText = String(format: "seen_x_times_last".localized(), times.description, getSimpleSecondsText(seconds: lastSeenSeconds, longerDate: false))
                            
                            CustomSection(header: timesText) {
                                DeviceEntryButton(device: elem, showAlerts: true, showSignal: false)
                                
                            }
                        }
                    }
                }
                
                Spacer()
                
            }
            .frame(maxWidth: Constants.maxWidth)
            .frame(maxWidth: .infinity)
            .padding(.bottom)
        }
        .modifier(CustomFormBackground())
        .navigationTitle("tracker_history")
        .modifier(GoToRootModifier(view: .ManualScan))
    }
}


struct Previews_OldTrackersView_Previews: PreviewProvider {
    
    static var previews: some View {
        TrackerHistoryView()
    }
}


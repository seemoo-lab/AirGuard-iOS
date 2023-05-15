//
//  RiskDetailView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 26.06.22.
//

import SwiftUI

struct RiskDetailView: View {
    
    let notifications: [TrackerNotification]
    @ObservedObject var clock = Clock.sharedInstance
    
    var body: some View {
        
        NavigationSubView() {
            
            ForEach(notifications) { elem in
                
                if let time = elem.time, let tracker = elem.baseDevice {
                    CustomSection(header: getSimpleSecondsText(seconds: Int(-time.timeIntervalSince(clock.currentDate)))) {
                        DeviceEntryButton(device: tracker)
                        
                    }
                }
            }
            
            if(notifications.count == 0) {
                BigSymbolViewWithText(title: "", symbol: "checkmark.shield.fill", subtitle: "no_trackers_detected_yet")
                
            }
            
            Spacer()
            
        }
        .navigationTitle("notifications")
        .modifier(GoToRootModifier(view: .HomeView))
    }
}


struct Previews_RiskDetailView_Previews: PreviewProvider {
    
    static var previews: some View {
        RiskDetailView(notifications: [])
    }
}

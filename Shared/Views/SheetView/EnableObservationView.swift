//
//  EnableObservationSheet.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.08.22.
//

import SwiftUI

struct EnableObservationView: View {
    
    @Binding var observationEnabled: Bool
    @ObservedObject var tracker: BaseDevice
    
    @State var showObserveUnavailableAlert = false
    @ObservedObject var settings = Settings.sharedInstance
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        
        BigButtonView(buttonHeight: Constants.BigButtonHeight, mainView: BigSymbolViewWithText(title: "observe_tracker", symbol: "clock.fill", subtitle: "observe_tracker_description", topPadding: 0), buttonView: GrayButton(label: "start_observation", action: {
            
            if(tracker.ignore || !settings.backgroundScanning || settings.lowPowerScan) {
                showObserveUnavailableAlert = true
            }
            else {
                observationEnabled = true
                presentationMode.wrappedValue.dismiss()
            }
            
        })
            .alert(isPresented: $showObserveUnavailableAlert, content: {
                Alert(title: Text("feature_unavailable"), message: Text("observing_unavailable_description"))
            }), hideNavigationBar: false
        )
    }
}


struct Previews_EnableObservationSheet_Previews: PreviewProvider {
    static var previews: some View {
        EnableObservationView(observationEnabled: .constant(false), tracker: BaseDevice(context: PersistenceController.sharedInstance.container.viewContext))
    }
}

//
//  TrackerForgetView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 29.02.24.
//

import SwiftUI

struct TrackerForgetView: View {
    
    let tracker: BaseDevice
    @State var showAlert = false
    
    var body: some View {
        LUIButton(action: {
            showAlert = true
        }, label: {
            Text("forget_tracker")
                .font(.system(size: 13))
                .foregroundColor(.grayColor.opacity(0.7))
                .underline(true)
        })
        .padding(5)
        .padding(.top)
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("forget_tracker_alert_header"), message: Text("forget_tracker_alert_description"), primaryButton: .destructive(Text("forget_tracker"), action: {
                delete()
            }), secondaryButton: .cancel())
        })
    }
    
    func delete() {
        Settings.sharedInstance.showSheet = false
        
        modifyDeviceOnBackgroundThread(objectID: tracker.objectID) { context, device in
            context.delete(device)
        }
    }
}

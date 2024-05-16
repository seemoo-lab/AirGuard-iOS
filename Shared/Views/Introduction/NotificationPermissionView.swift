//
//  NotificationPermissionView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.06.22.
//

import SwiftUI

struct NotificationPermissionView: View {
    
    @ObservedObject var notificationManager = NotificationManager.sharedInstance
    @ObservedObject var settings = Settings.sharedInstance
    
    var body: some View {
        
        PermissionView(title: "notification_access", symbol: "bell.fill", subtitle: "notification_access_description", action: {
            
            notificationManager.requestNotificationPermission() { success in
                if(success) {
                    IntroducationViewController.sharedInstance.canProceed = true
                }
                else {
                    openAppSettings()
                }
            }
            
        }, canSkip: true) {
            LocationPermissionView()
        }
    }
}


/// Opens the AirGuard's settings in `Settings` app
func openAppSettings() {
    if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
        UIApplication.shared.open(appSettings)
    }
}


struct Previews_NotificationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPermissionView()
    }
}

//
//  LocationAlwaysPermissionView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.06.22.
//

import SwiftUI

struct LocationAlwaysPermissionView: View {
    
    @ObservedObject var locationManager = LocationManager.sharedInstance
    @ObservedObject var settings = Settings.sharedInstance
    
    var body: some View {
        
        let canProceed = locationManager.locationManager?.authorizationStatus == .authorizedAlways
        
        PermissionView(title: "background_location", symbol: "mappin.circle.fill", subtitle: "background_location_description", action: {
            
            if(canProceed) {
                settings.backgroundScanning = true
                locationManager.enableBackgroundLocationUpdate()
                IntroducationViewController.sharedInstance.canProceed = true
            }
            else if(locationManager.locationManager?.authorizationStatus == .denied || locationManager.locationManager?.authorizationStatus == .restricted) {
                openAppSettings()
            }
            else {
                locationManager.requestAlwaysUsage()
                
                /// If the user prevously selected "Allow once" for location, no dialogue will appear when requesting always usage. We detect if a dialogue is shown using the background property. If the dialogue is show, the app is in background. If not, we open the app settings
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    if(!settings.isBackground) {
                        openAppSettings()
                    }
                })
            }
        
        }, canSkip: true) {
            if(settings.appLaunchedBefore) {
                IntroductionDoneView()
            }
            else if Constants.StudyIsActive {
                StudyOptInView()
            }else {
                IntroductionDoneView()
            }
            
        }
        .onChange(of: canProceed) { newValue in
            settings.backgroundScanning = true
            locationManager.enableBackgroundLocationUpdate()
            IntroducationViewController.sharedInstance.canProceed = true
        }
    }
}


struct Previews_LocationAlwaysPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        LocationAlwaysPermissionView()
    }
}


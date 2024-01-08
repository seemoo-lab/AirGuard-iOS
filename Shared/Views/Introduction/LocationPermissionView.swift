//
//  LocationPermissionView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.06.22.
//

import SwiftUI

struct LocationPermissionView: View {
    
    @ObservedObject var locationManager = LocationManager.sharedInstance
    
    var body: some View {
        
        let canProceed = locationManager.permissionSet
        
        PermissionView(title: "location_access", symbol: "mappin.circle.fill", subtitle: "location_access_description", action: {
            
            let authorizationStatus = locationManager.locationManager?.authorizationStatus ?? .notDetermined
            let authorizationAccuracy = locationManager.locationManager?.accuracyAuthorization ?? .none
            
            if(canProceed) {
                IntroducationViewController.sharedInstance.canProceed = true
            }
            if authorizationStatus == .notDetermined {
                locationManager.requestWhenInUse()
            } else if(locationManager.locationManager?.authorizationStatus == .denied || locationManager.locationManager?.authorizationStatus == .restricted) {
                openAppSettings()
            }
            
            if authorizationStatus == .authorizedWhenInUse && authorizationAccuracy != .fullAccuracy {
                openAppSettings()
            }
            
        }, canSkip: true) {
            LocationAlwaysPermissionView()
        }
        .onChange(of: canProceed) { newValue in
            IntroducationViewController.sharedInstance.canProceed = true
        }
    }
}

struct Previews_LocationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPermissionView()
    }
}

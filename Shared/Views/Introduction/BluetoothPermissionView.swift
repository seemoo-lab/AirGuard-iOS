//
//  BluetoothPermissionView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.06.22.
//

import SwiftUI


struct BluetoothPermissionView: View {
    
    @ObservedObject var bluetoothManager = BluetoothManager.sharedInstance
    
    var body: some View {
        
        let canProceed = bluetoothManager.centralManager?.state == .poweredOn || bluetoothManager.centralManager?.state == .poweredOff
        
        PermissionView(title: "bluetooth_access", symbol: "magnifyingglass", subtitle: "bluetooth_access_description", action: {
            
            bluetoothManager.startCentralManager()
            
            if(bluetoothManager.centralManager?.state == .unauthorized) {
                openAppSettings()
            }
            
            if isSimulator() || canProceed {
                IntroducationViewController.sharedInstance.canProceed = true
            }
            
        }) {
            NotificationPermissionView()
        }

        .onChange(of: canProceed) { newValue in
            IntroducationViewController.sharedInstance.canProceed = true
        }
    }
}

struct Previews_BluetoothPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothPermissionView()
    }
}

//
//  ManualScanningDeviceList.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 24.10.22.
//

import SwiftUI

struct TrackerSection: View {
    let trackers: [BaseDevice]
    let header: String
    let showHelp: Bool
    @State var showAlert = false
    
    var body: some View {
        
        let helpView = showHelp ?
        
        AnyView(Button(action: { showAlert = true }, label: {
            
            HStack(spacing: 5) {
                Text("safe_trackers")
                Image(systemName: "questionmark.circle")
            }
            
            .offset(x: -10)
            
        }))
        
        : AnyView(EmptyView())
        
        CustomSection(header: header, headerExtraView: helpView) {
            ForEach(trackers) { device in
                
                DeviceEntryButton(device: device, showAlerts: true)
                    .padding(.vertical, 1)
                
                if device != trackers.last {
                    CustomDivider()
                    
                }
            }
        }
        .frame(maxWidth: Constants.maxWidth)
        
        .alert(isPresented: $showAlert, content: {Alert(title: Text("safe_trackers_header"), message: Text("safe_trackers_description"))})
    }
}


struct DeviceEntryButton: View {
    
    @ObservedObject var device: BaseDevice
    @ObservedObject private var settings = Settings.sharedInstance
    
    @State private var showLoading = false
    @State var showAlerts: Bool = false
    
    var body: some View {
        
        Button {
            
            withAnimation(.easeInOut(duration: 0.001)) {
                showLoading = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                openSheet(withDevice: device)
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                
                // try again - if sheet is open/closed fast enough this case can happen
                if(!settings.showSheet) {
                    openSheet(withDevice: device)
                }
            })
            
        } label: {
            DeviceListEntryView(device: device, bluetoothData: BluetoothManager.sharedInstance.getBluetoothData(bluetoothID: device.currentBluetoothId ?? ""), showAlerts: showAlerts, showLoading: showLoading)
        }
        .foregroundColor(.primary)
        .buttonStyle(PlainButtonStyle())
        
        .onChange(of: settings.showSheet) { newValue in
            if(newValue) {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLoading = false
                    }
                }
            }
        }
    }
}


/// Opens the Tracker Detail View with the device. The device needs to be fetched from main thread!
func openSheet(withDevice: BaseDevice) {
    let settings = Settings.sharedInstance
    
    settings.selectedTracker = withDevice
    settings.showSheet = true
}

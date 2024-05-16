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
        
        CustomSection(header: header, headerExtraView: {
            
            Group {
                if showHelp {
                    LUIButton(action: { showAlert = true }, label: {
                        
                        HStack(spacing: 5) {
                            Text("safe_trackers")
                            Image(systemName: "questionmark.circle")
                        }
                        .foregroundColor(.airGuardBlue)
                        .offset(x: -10)
                    })
                }
            }
        }) {
            ForEach(trackers) { device in
                
                DeviceEntryButton(device: device, showAlerts: true)
                    .padding(.vertical, 1)
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
    @State var showSignal: Bool = true
    
    var body: some View {
        
        LUIButton {
            
            withAnimation(.easeInOut(duration: 0.001)) {
                showLoading = true
            }
            
            runAfter(seconds: 0.1) {
                openSheet(withDevice: device)
            }
            
            runAfter(seconds: 0.4) {
                // try again - if sheet is open/closed fast enough this case can happen
                if(!settings.showSheet) {
                    openSheet(withDevice: device)
                }
            }
            
        } label: {
            DeviceListEntryView(device: device, bluetoothData: BluetoothManager.sharedInstance.getBluetoothData(bluetoothID: device.currentBluetoothId ?? ""), showAlerts: showAlerts, showSignal: showSignal, showLoading: showLoading)
        }
        .foregroundColor(.primary)
        .buttonStyle(PlainButtonStyle())
        
        .onChange(of: settings.showSheet) { newValue in
            if(newValue) {
                
                runAfter(seconds: 0.3) {
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

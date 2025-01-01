//
//  DataCapturerView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 14.07.24.
//

import SwiftUI

struct DataCapturerView: View {
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BaseDevice.firstSeen, ascending: false)],
        predicate: NSPredicate(format: "lastSeen >= %@ AND deviceType != %@ AND deviceType != nil", Clock.sharedInstance.currentDate.addingTimeInterval(-20) as CVarArg, DeviceType.Unknown.rawValue),
        animation: .spring())
    private var devices: FetchedResults<BaseDevice>
    
    @ObservedObject var clock = Clock.sharedInstance
    
    @State var selectedType = DeviceType.Google
    @State var minRSSI = -40.0
    
    @State var recordedServiceData: [String] = []
    @State var recording = false
    
    var body: some View {
        NavigationSubView() {
            
            CustomSection(header: "Observed Device") {
                ForEach(DeviceType.getAvailableTypes(filterAvailableForBackgroundScanning: false)) { type in
                    HStack {
                        Text(type.constants.name)
                        
                        Spacer()
                        
                        if type == selectedType {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(minHeight: Constants.SettingsLabelHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedType = type
                    }
                }
            }
            
            CustomSection(header: "Min RSSI") {
                HStack {
                    Slider(value: $minRSSI, in: (-100.0)...(-20.0))
                        .frame(minHeight: Constants.SettingsLabelHeight)
                    Text(Int(minRSSI).description)
                }
                
                Toggle(isOn: $recording, label: {
                    SettingsLabel(imageName: "circle.fill", text: "Record", backgroundColor: .red)
                })
            }
 
            TrackerSection(trackers: getFilteredDevices(), header: "Matched Devices", showHelp: false)
            
            if recordedServiceData.count > 0 {
                CustomSection(header: "Recorded Data") {
                    ForEach(recordedServiceData, id: \.self) { data in
                        Text(data)
                            .frame(minHeight: Constants.SettingsLabelHeight)
                            .frame(maxWidth: .infinity)
                    }
                    
                }
            }
            
            if recordedServiceData.count > 0 {
                CustomSection {
                    LUIButton {
                        doubleVibration()
                        let pasteboard = UIPasteboard.general
                        
                        var string = ""
                        
                        for data in recordedServiceData {
                            string += "\(data)\n"
                        }
                        
                        pasteboard.string = string
                    } label: {
                        SettingsLabel(imageName: "doc.on.clipboard", text: "Copy Data")
                    }
                }
            }
   
        }
        .onChange(of: clock.currentDate) { newValue in
            
            if !recording {
                return
            }

            UIApplication.shared.isIdleTimerDisabled = true
            
            if let first = getFilteredDevices().first, let service = first.getType.constants.offeredService {
                
                let serviceData = getServiceData(advertisementData: first.bluetoothTempData().advertisementData_publisher, key: service)
                
                if let serviceData = serviceData, !recordedServiceData.contains(serviceData) {
                    recordedServiceData.append(serviceData)
                }
            }
        }
        .navigationTitle("DataCapture")
    }
    
    func getFilteredDevices() -> [BaseDevice] {
        return devices.filter({ $0.getType == selectedType && $0.lastSeen ?? .distantPast >= clock.currentDate.addingTimeInterval(-20) && $0.bluetoothTempData().rssi_publisher >= minRSSI})
    }
}

#Preview {
    NavigationView {
        DataCapturerView()
    }
}

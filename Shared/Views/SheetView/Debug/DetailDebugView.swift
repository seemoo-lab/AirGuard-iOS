//
//  DetailDebugView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.08.22.
//

import SwiftUI

struct DetailDebugView: View {
    
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var settings = Settings.sharedInstance
    @ObservedObject var bluetoothData: BluetoothTempData
    @State var showingDetections = false
    @State var loadingOwnerLink = false
    
    var body: some View {
        
        if(settings.debugMode) {
            LazyVStack {
                CustomSection(header: "Tracking Detection") {
                    LUIButton {
                        doubleVibration()
                        log("Adding fake detection...")
                        runAfter(seconds: 5) {
                            PersistenceController.sharedInstance.modifyDatabase { context in
                                tracker.lastSeen = Date()
                                TrackingDetection.sharedInstance.addDetectionEvent(toDevice: tracker, bluetoothData: bluetoothData, context: context)
                            }
                        }
                    } label: {
                        NavigationLinkLabel(imageName: "eye.fill", text: "Add Fake Detection", backgroundColor: .blue)
                    }
                    
                    
                    LUIButton {
                        doubleVibration()
                        log("Force Tracking Detection Check")
                        PersistenceController.sharedInstance.modifyDatabase { context in
                            TrackingDetection.sharedInstance.checkIfTracked(device: tracker, context: context)
                        }
                    } label: {
                        NavigationLinkLabel(imageName: "location.magnifyingglass", text: "Force Tracking Detection Check", backgroundColor: .gray)
                    }
                }
                
                if let peripheral = bluetoothData.peripheral_background {
                    CustomSection(header: "Bluetooth Actions") {
                        
                        
                        LUIButton {
                            doubleVibration()
                            BluetoothManager.sharedInstance.centralManager?.connect(peripheral)
                            peripheral.discoverServices(nil)
                            
                        } label: {
                            NavigationLinkLabel(imageName: "bolt.fill", text: "Connect", backgroundColor: .red)
                        }
                        
                        SettingsLabel(imageName: "bolt.fill", text: "Connected: \(bluetoothData.connected_publisher.description)", backgroundColor: .green)
                    }
                }
                
                if #available(iOS 15.0, *), tracker.getType == .Google {
                    CustomSection(header: "FMDN") {
                        FMDNDebugView(tracker: tracker)
                    } 
                }
                
                CustomSection(header: "All Detections") {
                    SettingsLabel(imageName: "number", text: "Detections: \(tracker.detectionEvents?.count ?? 0)", backgroundColor: .orange)
                    
                    if showingDetections {
                        if let detections = tracker.detectionEvents?.array as? [DetectionEvent] {
                            
                            ForEach(detections, id: \.self) { detection in
                                
                                SettingsLabel(imageName: "wave.3.right", text: "Time: \(getTime(date: detection.time))\n\(detection.connectionStatus?.description ?? "-")\(detection.isTraveling ? " - Travel" : "")")
                            }
                        }
                    }
                    else {
                        LUIButton {
                            withAnimation {
                                showingDetections = true
                            }
                        } label: {
                            NavigationLinkLabel(imageName: "eye", text: "Show All DetectionEvents")
                        }
                    }
                }
                
                CustomSection(header: "Bluetooth Data") {
                    
                    SettingsLabel(imageName: "info", text: "Last MAC Refresh: \(getTime(date: tracker.lastMacRenewal))")
                    
                    if let service = tracker.getType.constants.offeredService {
                        InfoAndCopyButton(label: "Service Data", info: getServiceData(advertisementData: bluetoothData.advertisementData_publisher, key: service))
                    }
                    
                    SettingsLabel(imageName: "info", text: "Additional Data: \(tracker.additionalData?.description ?? "---")")
                    
                    if let serv = bluetoothData.peripheral_background?.services {
                        ForEach(serv, id: \.self) { s in
                            InfoAndCopyButton(label: "Service offered", info: s.uuid.uuidString)
                        }
                    }
                }
                
                
                CustomSection {
                    
                    InfoAndCopyButton(label: "UniqueID", info: tracker.uniqueId)
                    InfoAndCopyButton(label: "CurrentBluetoothID", info: tracker.currentBluetoothId)
                    InfoAndCopyButton(label: "PeripheralID", info: bluetoothData.peripheral_background?.identifier.uuidString)
                    InfoAndCopyButton(label: "BluetoothDataID", info: bluetoothData.identifier_background)
                }
                
                CustomSection(header: "CoreBluetooth") {
                    Text(bluetoothData.advertisementData_publisher.description)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    func getTime(date: Date?) -> String {
        
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter.string(for: date) ?? "-"
        }
        return "-"
    }
}


struct InfoAndCopyButton: View {
    
    let label: String
    let info: String?
    
    var body: some View {
        let infoDescription = (info ?? "No Value")
        
        LUIButton {
            copyToClipboard(string: infoDescription)
        } label: {
            SettingsLabel(imageName: "info", text: "\(label): " + infoDescription)
        }
    }
    
    func copyToClipboard(string: String?) {
        if let string = string {
            doubleVibration()
            let pasteboard = UIPasteboard.general
            pasteboard.string = string
        }
    }
}

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
    
    var body: some View {
        
        if(settings.debugMode) {
            
            VStack {
                
                Button(action: {
                    PersistenceController.sharedInstance.modifyDatabase { context in
                        context.delete(tracker)
                    }
                }, label: {
                    Text("Core data delete entry")
                })
            }
            
            VStack {
                
                Text("Last MAC refresh: \(tracker.lastMacRenewal?.description ?? "---")")
                
                Text("Additional data: \(tracker.additionalData?.description ?? "---")")
                
                if let service = tracker.getType.constants.offeredService {
                    Text("service data: \(getServiceData(advertisementData: bluetoothData.advertisementData_publisher, key: service) ?? "no value")")
                }
            }
          
            
            if let serv = bluetoothData.peripheral_background?.services {
                ForEach(serv, id: \.self) { s in
                    Text(s.uuid.description)
                }
            }
            
            
            Button {
                log("Adding fake detection...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    PersistenceController.sharedInstance.modifyDatabase { context in
                        tracker.lastSeen = Date()
                        TrackingDetection.sharedInstance.addDetectionEvent(toDevice: tracker, bluetoothData: bluetoothData, context: context)
                    }
                })
               
            } label: {
                Text("Add fake detection event")
            }
            
            
            Text("Detections: \(tracker.detectionEvents?.count ?? 0)")
            
            
            if let peripheral = bluetoothData.peripheral_background {
                Button {
                    
                    BluetoothManager.sharedInstance.centralManager?.connect(peripheral)
                    peripheral.discoverServices(nil)
                    
                } label: {
                    Text("Connect")
                }
            }
            
            
            Text("Connected: \(bluetoothData.connected_background.description)")
            
            Text(bluetoothData.advertisementData_publisher.description)
            
            
            Group {
                Text("UniqueID: " + (tracker.uniqueId?.description ?? "no id"))
                Text("CurrentBluetoothID: " + (tracker.currentBluetoothId?.description ?? "no id"))
                Text("PeripheralID: " + (bluetoothData.peripheral_background?.identifier.description ?? "no id"))
                Text("BluetoothDataID: " + (bluetoothData.identifier_background))
            }
            
            
            VStack {
                if let detections = tracker.detectionEvents?.array as? [DetectionEvent] {
                    
                    ForEach(detections, id: \.self) { detection in
                        Text("\(detection.time?.description ?? "-") \(detection.connectionStatus?.description ?? "-")")
                        Button {
                            PersistenceController.sharedInstance.modifyDatabase { context in
                                context.delete(detection)
                            }
                        } label: {
                            Text("Delete")
                        }

                    }
                }
            }
        }
    }
}

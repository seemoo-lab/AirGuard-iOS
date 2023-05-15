//
//  DetailGeneralView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.08.22.
//

import SwiftUI

struct DetailGeneralView: View {
    
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var settings = Settings.sharedInstance
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var clock = Clock.sharedInstance
    
    let persistenceController = PersistenceController.sharedInstance
    
    @State var showPrecisionFinding = false
    @State var observingWasTurnedOn = false
    
    var body: some View {
        
        let notCurrentlyReachable = deviceNotCurrentlyReachable(device: tracker, currentDate: clock.currentDate)
        
        CustomSection(header: "general", footer: tracker.getType.constants.supportsIgnore ? "ignore_trackers_footer" : "") {
            
            VStack(spacing: 0) {
                
                Button {
                    showPrecisionFinding = true
                } label: {
                    NavigationLinkLabel(imageName: "smallcircle.fill.circle.fill", text: "locate_tracker", backgroundColor: .accentColor, status: notCurrentlyReachable ? "" : "nearby")
                }
                
                if tracker.getType.constants.supportsIgnore || tracker.getType.constants.supportsBackgroundScanning {
                    CustomDivider()
                }
                
                
                if(tracker.getType.constants.supportsBackgroundScanning
                ) {
                    
                    let binding = Binding {
                        
                        tracker.observingStartDate != nil
                        
                    } set: { newValue in
                        
                        if newValue {
                            observingWasTurnedOn = true
                            
                            modifyDeviceOnBackgroundThread(objectID: tracker.objectID) { context, tracker in
                                
                                TrackingDetection.sharedInstance.startObservingTracker(tracker: tracker, context: context)
                            }
                        }
                        else {
                            modifyDeviceOnBackgroundThread(objectID: tracker.objectID) { context, tracker in
                                
                                TrackingDetection.sharedInstance.stopObservingTracker(tracker: tracker, context: context)
                            }
                        }
                    }
                    
                    let color = Color(#colorLiteral(red: 0.3667442501, green: 0.422971189, blue: 0.9019283652, alpha: 1))
                    
                    if binding.wrappedValue || observingWasTurnedOn {
                        Toggle(isOn: binding) {
                            SettingsLabel(imageName: "clock.fill", text: "observe_tracker", backgroundColor: color)
                        }
                        .onAppear {
                            observingWasTurnedOn = true
                        }
                    }
                    else {
                        NavigationLink {
                            EnableObservationView(observationEnabled: binding, tracker: tracker)
                        } label: {
                            NavigationLinkLabel(imageName: "clock.fill", text: "observe_tracker", backgroundColor: color, status: "off")
                        }
                    }
                    
                    
                    if tracker.getType.constants.supportsIgnore {
                        CustomDivider()
                    }
                }
                
                if(tracker.getType.constants.supportsIgnore) {
                    
                    let binding = Binding(get: {return tracker.ignore}, set: { newValue in
                        
                        modifyDeviceOnBackgroundThread(objectID: tracker.objectID) { context, tracker in
                            
                            tracker.ignore = newValue
                            TrackingDetection.sharedInstance.stopObservingTracker(tracker: tracker, context: context)
                        }
                    })
                    

                    Toggle(isOn: binding) {
                        SettingsLabel(imageName: "nosign", text: "ignore_this_tracker", backgroundColor: .red)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPrecisionFinding, content: {PrecisionFindingView(tracker: tracker, bluetoothData: tracker.bluetoothTempData(), soundManager: soundManager, isShown: $showPrecisionFinding)})
    }
}



struct Previews_TrackerGeneralView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .Tile)
        device.firstSeen = Date()
        device.lastSeen = Date()
        
        try? vc.save()
        
        return NavigationView {
            TrackerDetailView(tracker: device, bluetoothData: BluetoothTempData(identifier: UUID().uuidString))
                .environment(\.managedObjectContext, vc)
        }
    }
}

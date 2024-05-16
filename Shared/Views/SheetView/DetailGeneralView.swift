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
        
        let type = tracker.getType
        let macAddessResetTime = type.constants.minMacAddressChangeTime
        let infoString = macAddessResetTime != nil ? String(format: "min_mac_address_change_time_info".localized(), type.constants.name, macAddessResetTime!.description) : String(format: "min_mac_address_change_time_changes_never_info".localized(), type.constants.name)
        
        CustomSection(header: "general", footer: infoString) {
                
            LUIButton {
                    showPrecisionFinding = true
                } label: {
                    NavigationLinkLabel(imageName: "smallcircle.fill.circle.fill", text: "locate_tracker", backgroundColor: .airGuardBlue, status: notCurrentlyReachable ? "" : "nearby")
                }
                
                
                if(tracker.getType.constants.supportsBackgroundScanning
                ) {
                    
                    let binding = Binding {
                        
                        tracker.observingStartDate != nil
                        
                    } set: { newValue in
                        
                        if newValue {
                            observingWasTurnedOn = true
                            
                            // Do this on main thread to avoid lag
                            PersistenceController.sharedInstance.modifyDatabase { context in
                                TrackingDetection.sharedInstance.startObservingTracker(tracker: tracker, context: context)
                            }
                        }
                        else {
                            // Do this on main thread to avoid lag
                            PersistenceController.sharedInstance.modifyDatabase { context in
                                
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
                        LUILink(destination: EnableObservationView(observationEnabled: binding, tracker: tracker), label: {
                            NavigationLinkLabel(imageName: "clock.fill", text: "observe_tracker", backgroundColor: color, status: "off")
                        })
                    }
                }
                
                if(tracker.getType.constants.supportsIgnore) {
                    
                    let binding = Binding(get: {return tracker.ignore}, set: { newValue in
                        
                        // Do this on main thread to avoid lag
                        PersistenceController.sharedInstance.modifyDatabase { context in
                            
                            tracker.ignore = newValue
                            TrackingDetection.sharedInstance.stopObservingTracker(tracker: tracker, context: context)
                        }
                    })
                    

                    Toggle(isOn: binding) {
                        SettingsLabel(imageName: "nosign", text: "ignore_this_tracker", backgroundColor: .red)
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

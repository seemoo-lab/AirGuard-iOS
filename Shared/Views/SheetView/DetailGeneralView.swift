//
//  DetailGeneralView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.08.22.
//

import SwiftUI

struct DetailGeneralView: View {
    
    internal init(tracker: BaseDevice, soundManager: SoundManager) {
        self.tracker = tracker
        self.soundManager = soundManager
        self.isBeingObserved = tracker.observingStartDate != nil
        self.observingWasTurnedOn = tracker.observingStartDate != nil
        self.ignore = tracker.ignore
    }
    
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var settings = Settings.sharedInstance
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var clock = Clock.sharedInstance
    
    let persistenceController = PersistenceController.sharedInstance
    
    @State var showPrecisionFinding = false
    
    @State var isBeingObserved: Bool
    @State var observingWasTurnedOn: Bool
    @State var ignore: Bool
    
    var body: some View {
        
        let notCurrentlyReachable = deviceNotCurrentlyReachable(device: tracker, currentDate: clock.currentDate)
        
        let type = tracker.getType
        let macAddessResetTime = type.constants.minMacAddressChangeTime
        let infoString = macAddessResetTime != nil ? String(format: "min_mac_address_change_time_info".localized(), macAddessResetTime!.description) : "min_mac_address_change_time_changes_never_info".localized()
        
        CustomSection(header: "general", footer: infoString) {
                
            LUIButton {
                    showPrecisionFinding = true
                } label: {
                    NavigationLinkLabel(imageName: "smallcircle.fill.circle.fill", text: "locate_tracker", backgroundColor: .airGuardBlue, status: notCurrentlyReachable ? "" : "nearby")
                }
                
                
                if(tracker.getType.constants.supportsBackgroundScanning
                ) {
                    
                    let binding = Binding {
                        isBeingObserved
                    } set: { newValue in
                        
                        if newValue {
                            observingWasTurnedOn = true
                            isBeingObserved = true
                            
                            modifyDeviceOnBackgroundThread(objectID: tracker.objectID) { context, tracker in

                                TrackingDetection.sharedInstance.startObservingTracker(tracker: tracker, context: context)
                            }
                        }
                        else {
            
                            isBeingObserved = false
                            modifyDeviceOnBackgroundThread(objectID: tracker.objectID) { context, tracker in

                                TrackingDetection.sharedInstance.stopObservingTracker(tracker: tracker, context: context)
                            }
                        }
                    }
                    
                    let color = Color(#colorLiteral(red: 0.3667442501, green: 0.422971189, blue: 0.9019283652, alpha: 1))
                    
                    if isBeingObserved || observingWasTurnedOn {
                        Toggle(isOn: binding) {
                            SettingsLabel(imageName: "clock.fill", text: "observe_tracker", backgroundColor: color)
                        }
                        .onChange(of: tracker.observingStartDate) { newValue in
                            // this can happen if the sheet was open, and the tracker observation expired
                            if newValue == nil && isBeingObserved {
                                isBeingObserved = false
                            }
                        }
                    }
                    else {
                        LUILink(destination: EnableObservationView(observationEnabled: binding, tracker: tracker), label: {
                            NavigationLinkLabel(imageName: "clock.fill", text: "observe_tracker", backgroundColor: color, status: "off")
                        })
                    }
                }
                
                if(tracker.getType.constants.supportsIgnore) {
                    
                    let binding = Binding {
                        ignore // local ignore variable to "fake" being quicker, if background operation takes longer to complete
                    } set: { newValue in
                        ignore = newValue
                        isBeingObserved = false
                        
                        modifyDeviceOnBackgroundThread(objectID: tracker.objectID) { context, tracker in
                            tracker.ignore = newValue
                            TrackingDetection.sharedInstance.stopObservingTracker(tracker: tracker, context: context)
                        }
                    }

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

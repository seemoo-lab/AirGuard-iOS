//
//  ManualScanningView.swift
//  AirGuard
//
//  Created by Leon Böttger on 03.05.22.
//

import SwiftUI


struct ManualScanningView: View {
    
    @ObservedObject var settings = Settings.sharedInstance
    @ObservedObject var bluetoothManager = BluetoothManager.sharedInstance
    @ObservedObject var locationManager = LocationManager.sharedInstance
    @ObservedObject var reader = NFCReader.sharedInstance
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BaseDevice.firstSeen, ascending: true)],
        predicate: NSPredicate(format: "lastSeen >= %@ AND deviceType != %@ AND deviceType != nil", Clock.sharedInstance.currentDate.addingTimeInterval(-Constants.manualScanBufferTime) as CVarArg, DeviceType.Unknown.rawValue),
        animation: .spring())
    private var devices: FetchedResults<BaseDevice>
    
    @StateObject var clock = Clock.sharedInstance
    
    let timer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()
    
    @State var showStillSearchingHint = false
    
    /// Width and height of the scanning animation.
    private let scanAnimationSize: CGFloat = 72
    
    var body: some View {
        
        NavigationView {
            
            let trackers = settings.isBackground ? [] :
            devices.filter({($0.lastSeen ?? Date.distantPast) > clock.currentDate.addingTimeInterval(-Constants.manualScanBufferTime) })
            
            let count = trackers.count
            
            NavigationSubView {
                
                let size = scanAnimationSize
                
                if bluetoothManager.turnedOn {
                    
                    ScanAnimation(size: size)
                        .padding()
                }
                
                VStack(spacing: 0) {
                    
                    if !bluetoothManager.turnedOn {
                        
                        ExclamationmarkView()
                            .foregroundColor(.accentColor)
                            .padding(.bottom)
                        
                        VStack(spacing: 10) {
                            Text(getBluetoothProblemHeader())
                                .font(.system(.title))
                            Text(getBluetoothProblemSubHeader())
                                .padding(.horizontal)
                                .lowerOpacity(darkModeAsWell: true)
                        }
                    }
                    
                    else {
                        let timeRemaining = Int(-clock.currentDate.timeIntervalSince(settings.lastAppStart.addingTimeInterval(60)))
                        
                        ZStack {
                            
                            let showWaitTime = timeRemaining > 0 && showStillSearchingHint
                            
                            Text(.init(String(format: "we_detected_X_trackers_around_you".localized(), "\(getBoldString())\(count)", (count == 1 ? "tracker_singular".localized() : "tracker_plural".localized())+getBoldString())))
                                .opacity(showWaitTime ? 0 : 1)
                            
                            
                            Text(.init(String(format: "manual_scanning_wait".localized(), getBoldString()+timeRemaining.description+"s"+getBoldString())))
                                .opacity(showWaitTime ? 1 : 0)
                            
                        }
                        
                        .opacity(0.9)
                        .padding(.horizontal)
                        .onReceive(timer) { input in
                            
                            if !(timeRemaining > 0 && !settings.isBackground) {
                                withAnimation {
                                    showStillSearchingHint = false
                                }
                            }
                            else {
                                withAnimation {
                                    showStillSearchingHint.toggle()
                                }
                            }
                        }
                    }
                }
                .centered()
                .lowerOpacity()
                .padding(.bottom)
                .padding(.top)
                
                VStack(spacing: Constants.SettingsSectionSpacing) {
                    
                    let mayBeTracking = trackers.filter({!trackerIsSafe(tracker: $0)})
                    
                    let safeTrackers = trackers.filter({trackerIsSafe(tracker: $0)})
                    
                    if mayBeTracking.count > 0 {
                        TrackerSection(trackers: mayBeTracking, header: "", showHelp: false)
                    }
                    
                    if safeTrackers.count > 0 {
                        TrackerSection(trackers: safeTrackers, header: " ", showHelp: true)
                    }
                }
                
                NavigationLink(destination: {
                    TrackerHistoryView()
                }, label: {
                    Text("older_trackers".localized() + "...")
                        .centered()
                        .lowerOpacity(darkModeAsWell: true)
                        .padding()
                })
                .padding(.top, trackers.count == 0 ? 0 : 10)
            }
            .animation(.spring(), value: count)
            .animation(.spring(), value: trackers)
            .navigationBarTitle("scan")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


/// Returns true if we consider the tracker to be safe.
func trackerIsSafe(tracker: BaseDevice) -> Bool {
    return tracker.ignore || tracker.getType.constants.connectionStatus(advertisementData: tracker.bluetoothTempData().advertisementData_publisher) == .OwnerConnected
}


/// Returns the error header when there is no access to Bluetooth
func getBluetoothProblemHeader() -> String {
    return (BluetoothManager.sharedInstance.centralManager?.state == .unauthorized ? "no_bluetooth_access" : "bluetooth_off").localized()
}


/// Returns the error description when there is no access to Bluetooth
func getBluetoothProblemSubHeader() -> String {
    return (BluetoothManager.sharedInstance.centralManager?.state == .unauthorized ? "no_bluetooth_access_description" : "bluetooth_off_description").localized()
}


struct Previews_ManualScanningView_Previews: PreviewProvider {
    
    static var previews: some View {
        ManualScanningView()
            .onAppear{
                Settings.sharedInstance.isBackground = false
                BluetoothManager.sharedInstance.turnedOn = true
            }
    }
}

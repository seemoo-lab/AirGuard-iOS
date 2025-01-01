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
    @State var showDangerousTrackersHint = false
    
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
                            .foregroundColor(.airGuardBlue)
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
                        
                        ZStack {
                            
                            Text(.init(String(format: "we_detected_X_trackers_around_you".localized(), "\(getBoldString())\(count)", (count == 1 ? "tracker_singular".localized() : "tracker_plural".localized())+getBoldString())))
                                .opacity(showStillSearchingHint ? 0 : 1)
                            
                            Text(.init(getSecondaryHint()))
                                .opacity(showStillSearchingHint ? 1 : 0)
                            
                        }
                        .modifier(MonospacedDigitModifer())
                        .opacity(0.9)
                        .padding(.horizontal)
                        .onReceive(timer) { input in
                            withAnimation {
                                showStillSearchingHint.toggle()
                                
                                if !showStillSearchingHint && !trackers.isEmpty {
                                    showDangerousTrackersHint.toggle()
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
                
                LUILink(destination: TrackerHistoryView(), label: {
                    Text("previously_found".localized() + "...")
                        .font(.system(size: 13))
                        .foregroundColor(.grayColor)
                        .underline(true)
                        .centered()
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
    
    func getSecondaryHint() -> String {
        
        let timeRemaining = Int(-clock.currentDate.timeIntervalSince(settings.lastAppStart.addingTimeInterval(60)))
        
        if showDangerousTrackersHint {
            return "manual_scan_dangerous_hint".localized()
        }
        
        if timeRemaining > 0 {
            return String(format: "manual_scanning_wait".localized(), getBoldString()+timeRemaining.description+"s"+getBoldString())
        }
        
        return "manual_scan_own_devices_hint".localized()
    }
}


struct MonospacedDigitModifer: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            return content.monospacedDigit()
        }
        else {
            return content
        }
    }
}


/// Returns true if we consider the tracker to be safe.
func trackerIsSafe(tracker: BaseDevice) -> Bool {
    return tracker.ignore || !tracker.getType.constants.connectionStatus(advertisementData: tracker.bluetoothTempData().advertisementData_publisher).isInTrackingMode()
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

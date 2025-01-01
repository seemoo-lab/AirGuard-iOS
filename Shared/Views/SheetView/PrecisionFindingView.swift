//
//  PrecisionFindingView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 11.09.22.
//

import SwiftUI
import Combine


struct PrecisionFindingView: View {
    
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var bluetoothData: BluetoothTempData
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var clock = Clock.sharedInstance
    @State private var showSoundErrorInfo = false
    @Binding var isShown: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var isStarted = false
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    var body: some View {
        
        let maxRSSI = Double(tracker.getType.constants.bestRSSI)
        
        let notReachable = deviceNotCurrentlyReachable(device: tracker, currentDate: clock.currentDate, timeout: 45)
        
        let rssi = !isStarted || notReachable ? Constants.worstRSSI : Double(bluetoothData.rssi_publisher)
        
        let pct = rssiToPercentage(rssi: rssi, bestRSSI: maxRSSI)
        
        let delay: CGFloat = 2
        
        GeometryReader { geo in
            
            let fullHeight = geo.size.height
            
            ZStack {
                
                VStack(spacing: 0) {
                    
                    ZStack {
                        Color.airGuardBlue.opacity(colorScheme.isLight ? 0.9 : 1)
                        LinearGradient(colors: [.clear, .white.opacity(0.3)], startPoint: .bottom, endPoint: .top)
                        
                        PrecisionOverlayElements(tracker: tracker, soundManager: soundManager, pct: pct, rssi: rssi, animationDelay: delay, textColor: .white, notReachable: notReachable)
                        
                            .padding(safeAreaInsets)
                            .frame(height: fullHeight)
                    }
                    .frame(height: fullHeight * pct, alignment: .bottom)
                    .clipped()
                }
                .frame(height: fullHeight, alignment: .bottom)
                
                VStack(spacing: 0) {
                    
                    ZStack {
                        
                        Color.sheetBackground
                        
                        PrecisionOverlayElements(tracker: tracker, soundManager: soundManager, pct: pct, rssi: rssi, animationDelay: delay, textColor: .mainColor, notReachable: notReachable)
                            .padding(safeAreaInsets)
                            .frame(height: fullHeight)
                        
                    }
                    .frame(height: fullHeight * (1-pct), alignment: .top)
                    .clipped()
                }
                .frame(height: fullHeight, alignment: .top)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: delay), value: pct)
        
        .onAppear{
            isStarted = true
            startScan()
        }
        .onDisappear{
            BluetoothManager.sharedInstance.disableFastScan()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                runAfter(seconds: 1) {
                    startScan()
                }
            }
        }
    }
    
    func startScan() {
        var uuids = [UUID]()
        if let trackerUUIDstring = tracker.currentBluetoothId, let trackerUUID = UUID(uuidString: trackerUUIDstring) {
            uuids.append(trackerUUID)
        }
        
        if(tracker.getType.constants.supportsBackgroundScanning) {
            BluetoothManager.sharedInstance.enableFastScan(for: RSSIScan(service: tracker.getType.constants.offeredService), allowedUUIDs: uuids)
        }
        else {
            BluetoothManager.sharedInstance.enableFastScan(for: RSSIScan(bluetoothDevice: tracker.currentBluetoothId), allowedUUIDs: uuids)
        }
    }
}


struct PrecisionOverlayElements: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var soundManager: SoundManager
    @State var lastVibration = Date.distantPast
    let pct: CGFloat
    let rssi: CGFloat
    let animationDelay: CGFloat
    let textColor: Color
    let notReachable: Bool
    
    var body: some View {
        
        VStack {
            
            Text(tracker.getName)
                .bold()
                .font(.largeTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(textColor)
                .padding()
                .padding(.top)
            
            Spacer()
            
            Indicator(pct: pct, color: textColor)
                .onChange(of: pct, perform: {[pct] newPct in
                    if newPct == 0 {
                        errorVibration()
                    } else if abs(pct - newPct) > 0.05, self.lastVibration.isOlderThan(seconds: 5) {
                        lastVibration = Date()
                        if pct > newPct {
                            // User is going away
                            errorVibration()
                        }else {
                            // User is getting closer
                            doubleVibration()
                        }
                    }
                })
            
            Group {
                if(notReachable) {
                    
                    HStack {
                        Text("trying_connection")
                        
                        ProgressView()
                            .padding(5)
                    }
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.1)))
                }
                else {
                    Text("precision_finding_hint")
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.1)))
                }
            }
            .opacity(textColor == .white ? 1 : 0.7)
            .foregroundColor(textColor)
            .padding(.horizontal)
            .centered()
            .padding()
            
            Spacer()
            
            SoundAndCloseView(soundManager: soundManager, tracker: tracker, bluetoothData: tracker.bluetoothTempData(), notReachable: notReachable)
        }
    }
}


struct SoundAndCloseView: View {
    
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var tracker: BaseDevice
    @State private var showSoundErrorInfo = false
    @ObservedObject var bluetoothData: BluetoothTempData
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    let notReachable: Bool
    
    var body: some View {
        
        let rightLabelColor = Color.mainColor.opacity(0.5)
        
        CustomSection(backgroundColor: Color.white.opacity(colorScheme.isLight ? 0.8 : 0.1)) {
            if(!notReachable && tracker.getType.constants.canPlaySound && tracker.getType.constants.connectionStatus(advertisementData: bluetoothData.advertisementData_publisher) != .Connected) {
                LUIButton {
                    lightVibration()
                    soundManager.playSound(constants: tracker.getType.constants, bluetoothUUID: tracker.currentBluetoothId)
                } label: {
                    HStack {
                        SettingsLabel(imageName: "speaker.wave.2.fill", text: "play_sound", backgroundColor: .orange)
                            .fixedSize(horizontal: true, vertical: false)
                        
                        ZStack(alignment: .trailing) {
                            HStack {
                                Text("connecting_in_progress")
                                    .lineLimit(1)
                                    .foregroundColor(rightLabelColor)
                                    .padding(.trailing, 7)
                                ProgressView()
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .opacity(soundManager.soundRequest ? 1 : 0)
                            
                            
                            Text("playing_in_progress")
                                .lineLimit(1)
                                .foregroundColor(rightLabelColor)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .opacity(soundManager.playingSound ? 1 : 0)
                            
                            if let error = soundManager.error {
                                Text(error.title)
                                    .lineLimit(1)
                                    .foregroundColor(rightLabelColor)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .alert(isPresented: $showSoundErrorInfo, content: {
                            Alert(title: Text(soundManager.error?.title ?? ""), message: Text(soundManager.error?.description ?? ""))
                        })
                        
                        .onChange(of: soundManager.error) { val in
                            if(val != nil) {
                                showSoundErrorInfo = true
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
            
            if let url = URL(string: "http://www.google.com/search?q=\(tracker.getName) Tracker&tbm=isch") {
                Link(destination: url, label: {
                    SettingsLabel(imageName: "eye.fill", text: "tracker_appearance_button", backgroundColor: .green)
                })
                .buttonStyle(LUIButtonStyle())
            }
            
            
            LUIButton {
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            } label: {
                SettingsLabel(imageName: "xmark", text: "close_stop_searching", backgroundColor: .red)
            }
        }
        .frame(maxWidth: Constants.maxWidth)
        .padding(.bottom)
    }
}


struct Indicator: View {
    var pct: CGFloat
    let color: Color
    
    var body: some View {
        
        Color.clear
        
            .frame(height: 100)
            .modifier(PercentageIndicator(pct: self.pct, color: color))
            .padding(.horizontal)
    }
}


struct PercentageIndicator: AnimatableModifier {
    var pct: CGFloat = 0
    let color: Color
    
    var animatableData: CGFloat {
        get { pct }
        set { pct = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(LabelView(pct: pct, color: color))
    }
    
    struct ArcShape: Shape {
        let pct: CGFloat
        
        func path(in rect: CGRect) -> Path {
            
            var p = Path()
            
            p.addArc(center: CGPoint(x: rect.width / 2.0, y:rect.height / 2.0),
                     radius: rect.height / 2.0 + 5.0,
                     startAngle: .degrees(0),
                     endAngle: .degrees(360.0 * Double(pct)), clockwise: false)
            
            return p.strokedPath(.init(lineWidth: 10, lineCap: .round))
        }
    }
    
    struct LabelView: View {
        let pct: CGFloat
        let color: Color
        
        var body: some View {
            Text("\(Int(pct * 100))%")
            
                .font(.system(size: 100))
                .fontWeight(.ultraLight)
                .foregroundColor(color)
            
        }
    }
}


struct Previews_PrecisionFindingView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .AirTag)
        
        let tempdata = BluetoothTempData(identifier: "XY")
        tempdata.rssi_background = -80
        
        try? vc.save()
        
        return NavigationView {
            PrecisionFindingView(tracker: device, bluetoothData: tempdata, soundManager: SoundManager(), isShown: .constant(true))
                .environment(\.managedObjectContext, vc)
        }
    }
}

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
        
        let notReachable = deviceNotCurrentlyReachable(device: tracker, currentDate: clock.currentDate, timeout: 15)
        
        let rssi = !isStarted || notReachable ? Constants.worstRSSI : Double(bluetoothData.rssi_publisher)
        
        let pct = rssiToPercentage(rssi: rssi, bestRSSI: maxRSSI)
        
        let delay: CGFloat = 2
        
        GeometryReader { geo in
            
            let fullHeight = geo.size.height
            
            ZStack {
                
                VStack(spacing: 0) {
                    
                    ZStack {
                        Color.accentColor.opacity(colorScheme.isLight ? 0.8 : 1)
                        
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
                        
                        (colorScheme.isLight ? Color.white : Color.formDeepGray)
                        
                        PrecisionOverlayElements(tracker: tracker, soundManager: soundManager, pct: pct, rssi: rssi, animationDelay: delay, textColor: Color("DarkBlue"), notReachable: notReachable)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    startScan()
                })
            }
        }
    }
    
    func startScan() {
        if(tracker.getType.constants.supportsBackgroundScanning) {
            BluetoothManager.sharedInstance.enableFastScan(for: RSSIScan(service: tracker.getType.constants.offeredService))
        }
        else {
            BluetoothManager.sharedInstance.enableFastScan(for: RSSIScan(bluetoothDevice: tracker.currentBluetoothId))
        }
    }
}


struct PrecisionOverlayElements: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var soundManager: SoundManager
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
                .foregroundColor(textColor)
                .padding()
                .padding(.top)
            
            Spacer()
            
            Indicator(pct: pct, color: textColor)
            
                .onChange(of: rssi) { val in
                    
                    if val == Constants.worstRSSI {
                        errorVibration()
                    }
                    else {
                        doubleVibration()
                    }
                }
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
            
            SoundAndCloseView(soundManager: soundManager, tracker: tracker)
        }
    }
}


struct SoundAndCloseView: View {
    
    @ObservedObject var soundManager: SoundManager
    @ObservedObject var tracker: BaseDevice
    @State private var showSoundErrorInfo = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        
        CustomSection() {
            VStack(spacing: 0) {
                if(tracker.getType.constants.canPlaySound) {
                    Button {
                        mediumVibration()
                        soundManager.playSound(constants: tracker.getType.constants, bluetoothUUID: tracker.currentBluetoothId)
                    } label: {
                        HStack {
                            SettingsLabel(imageName: "speaker.wave.2.fill", text: "play_sound", backgroundColor: .orange)
                                .fixedSize(horizontal: true, vertical: false)
                            
                            ZStack {
                                HStack {
                                    
                                    Spacer()
                                    
                                    Text("connecting_in_progress")
                                        .lineLimit(1)
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 7)
                                    ProgressView()
                                }
                                .opacity(soundManager.soundRequest ? 1 : 0)
                                
                                HStack {
                                    Spacer()
                                    Text("playing_in_progress")
                                        .lineLimit(1)
                                        .foregroundColor(.gray)
                                    
                                }.opacity(soundManager.playingSound ? 1 : 0)
                                
                                if let error = soundManager.error {
                                    
                                    HStack {
                                        Spacer()
                                        Text(error.title)
                                            .lineLimit(1)
                                            .foregroundColor(.gray)
                                        
                                    }
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
                    }
                    
                    CustomDivider()
                }
                Button {
                    DispatchQueue.main.async {
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    SettingsLabel(imageName: "xmark", text: "close_stop_searching", backgroundColor: .red)
                }
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
        tempdata.rssi_background = -50
        
        try? vc.save()
        
        return NavigationView {
            PrecisionFindingView(tracker: device, bluetoothData: tempdata, soundManager: SoundManager(), isShown: .constant(true))
                .environment(\.managedObjectContext, vc)
        }
    }
}

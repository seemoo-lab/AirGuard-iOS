//
//  TrackerDetailView.swift
//  AirGuard
//
//  Created by Leon Böttger on 03.05.22.
//

import SwiftUI
import CoreBluetooth
import MapKit


struct TrackerDetailView: View {
    
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var bluetoothData: BluetoothTempData
    @StateObject var soundManager = SoundManager()
    @ObservedObject var clock = Clock.sharedInstance
    
    let persistenceController = PersistenceController.sharedInstance
    @State var showFeedbackSheet = false
    
    var body: some View {
        
        // Calculated here for animation
        let notCurrentlyReachable = deviceNotCurrentlyReachable(device: tracker, currentDate: clock.currentDate)

        let showingBanner = !tracker.ignore && !((tracker.notifications?.array as? [TrackerNotification] ?? []).last?.providedFeedback ?? true)
        
        NavigationSubView(spacing: Constants.SettingsSectionSpacing) {

            DetailTopView(tracker: tracker, bluetoothData: bluetoothData, notCurrentlyReachable: notCurrentlyReachable)

            DetailMapView(tracker: tracker)
            
            if showingBanner {
                FeedbackBannerView(showSheet: $showFeedbackSheet, tracker: tracker)
                    .padding(.top, -65)
            }

            DetailGeneralView(tracker: tracker, soundManager: soundManager)
            DetailNotificationsView(tracker: tracker)
            
            DetailMoreView(tracker: tracker)
            DetailDebugView(tracker: tracker, bluetoothData: bluetoothData)
            
            TrackerForgetView(tracker: tracker)
        }
        .animation(.spring(), value: tracker.ignore)
        .animation(.spring(), value: notCurrentlyReachable)
        .animation(.spring(), value: showingBanner)
        .navigationBarTitle("‏‏‎ ‎‎", displayMode: .inline)
        .luiSheet(isPresented: $showFeedbackSheet, content: {
            if let last = (tracker.notifications?.array as? [TrackerNotification] ?? []).last {
                NavigationView {
                    FalseAlarmFeedbackView(notification: last, showSheet: $showFeedbackSheet)
                }
            }
        })
    }
}


struct FeedbackBannerView: View {
    
    @Binding var showSheet: Bool
    let tracker: BaseDevice
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("feedback_banner_description")
            }
            Image(systemName: "chevron.right")
                .padding(.leading, 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 13)
        .foregroundColor(.white)
        .background(
            ZStack {
                Color.red
                Color.white.opacity(0.1)
                LinearGradient(colors: [.clear, .white.opacity(0.15)], startPoint: .bottom, endPoint: .top)
            }
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
        )
        .padding(.horizontal, Constants.FormHorizontalPadding)
        .onTapGesture {
            showSheet = true
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


struct Previews_TrackerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .Tile)
        device.firstSeen = Date()
        device.lastSeen = Date()
        
        let detectionEvent = DetectionEvent(context: vc)
        
        detectionEvent.time = device.lastSeen
        detectionEvent.baseDevice = device
        
        let location = Location(context: vc)
        
        location.latitude = 52
        location.longitude = 8
        location.accuracy = 1
        
        detectionEvent.location = location
        
        try? vc.save()
        
        return NavigationView {
            TrackerDetailView(tracker: device, bluetoothData: BluetoothTempData(identifier: UUID().uuidString))
                .environment(\.managedObjectContext, vc)
        }
    }
}

//
//  EntryDetailView.swift
//  AirGuard
//
//  Created by Leon Böttger on 02.05.22.
//

import SwiftUI


struct DeviceListEntryView: View {
    
    @ObservedObject var device: BaseDevice
    @ObservedObject var bluetoothData: BluetoothTempData
    @ObservedObject var clock = Clock.sharedInstance
    @ObservedObject var settings = Settings.sharedInstance
    @Environment(\.colorScheme) var colorScheme
    
    @State var showAlerts: Bool = false
    @State var showSignal: Bool = true
    let showLoading: Bool
    
    var body: some View {
        
        HStack {
            
            let color = Color.airGuardBlue.opacity(colorScheme.isLight ? 0.8 : 1)
            
            device.getType.constants.iconView
                .padding(.trailing, 3)
            
            Text(device.getName)
                .foregroundColor(.mainColor)
                .padding(.vertical)
            
            Spacer()
            
            if showAlerts && showSignal {
                BellIcon(device: device)
                    .foregroundColor(color)
            }
            
            ZStack {
                
                ZStack {
                    if showSignal {
                        SmallRSSIIndicator(
                            rssi: deviceNotCurrentlyReachable(device: device, currentDate: clock.currentDate) ? Constants.worstRSSI : Double(bluetoothData.rssi_publisher),
                            bestRSSI: Double(device.getType.constants.bestRSSI),
                            color: color)
                    }
                    else {
                        BellIcon(device: device)
                            .foregroundColor(color)
                    }
                }
                .opacity(showLoading ? 0 : 1)
                
                ProgressView()
                    .opacity(showLoading ? 1 : 0)
                
            }
            .frame(width: 20)
            
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
            
        }
        .contentShape(Rectangle())
    }
}


struct BellIcon: View {
    
    @ObservedObject var device: BaseDevice
    
    var body: some View {
        if let count = device.notifications?.count, count > 0, !device.ignore {
            Image(systemName: "bell.fill")
                .frame(width: 23)
        }
    }
}


struct Previews_DeviceListEntryView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .AirTag)
        
        try? vc.save()
        
        return NavigationView {
            DeviceListEntryView(device: device, bluetoothData: BluetoothTempData(identifier: UUID().uuidString), showAlerts: true, showLoading: false)
                .environment(\.managedObjectContext, vc)
                .padding()
        }
    }
}


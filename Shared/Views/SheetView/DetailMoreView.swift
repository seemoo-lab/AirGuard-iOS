//
//  DetailMoreView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.08.22.
//

import SwiftUI

struct DetailMoreView: View {
    
    @ObservedObject var tracker: BaseDevice
    @StateObject var nfcReader = NFCReader.sharedInstance
    @ObservedObject var bluetoothData: BluetoothTempData
    
    var body: some View {
        
        let connectionStatus = tracker.getType.constants.connectionStatus(advertisementData: bluetoothData.advertisementData_publisher)
        
        let constants = tracker.getType.constants
        let supportsNFC = (constants.supportsOwnerInfoOverNFC && !isiPad())
        let supportsBluetooth = constants.supportsOwnerInfoOverBluetooth && connectionStatus.isInTrackingMode()
        
        let ownerInfoSupport = supportsNFC || supportsBluetooth
        
        if(ownerInfoSupport || constants.supportURL != nil) {
            
            CustomSection(header: "more", footer: "more_trackerdetailview_description") {
                
                if supportsNFC {
                    LUIButton {
                        nfcReader.scan(infoMessage: String(format: "nfc_description".localized(), tracker.getName))
                    } label: {
                       ownerInfoLabel
                    }
                }
                if supportsBluetooth {
                    LUILink(destination: FMDNOwnerInfoView(tracker: tracker)) {
                        ownerInfoLabel
                    }
                }
                
                if constants.supportURL != nil {
                    LUIButton {
                        if let urlString = constants.supportURL, let url = URL(string: urlString) {
                            openURL(url: url)
                        }
                    } label: {
                        NavigationLinkLabel(imageName: "info", text: "website_manufacturer", backgroundColor: .green, isNavLink: false)
                    }
                }
            }
        }
    }
    
    var ownerInfoLabel: some View {
        NavigationLinkLabel(imageName: "person.fill", text: "more_trackerdetailview_owner_information", backgroundColor: Color(#colorLiteral(red: 1, green: 0.6991065145, blue: 0.003071677405, alpha: 1)), isNavLink: true)
    }
}


struct Previews_TrackerInfoView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .Google)
        device.firstSeen = Date()
        device.lastSeen = Date()
        
        try? vc.save()
        
        return NavigationView {
            TrackerDetailView(tracker: device, bluetoothData: BluetoothTempData(identifier: UUID().uuidString))
                .environment(\.managedObjectContext, vc)
        }
    }
}

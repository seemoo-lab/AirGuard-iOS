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
    
    var body: some View {
        
        let constants = tracker.getType.constants
        
        let nfcSupport = constants.supportsNFC && !isiPad()
        
        if(nfcSupport || constants.supportURL != nil) {
            
            CustomSection(header: "more", footer: "more_trackerdetailview_description") {
                
                let color = Color(#colorLiteral(red: 1, green: 0.6991065145, blue: 0.003071677405, alpha: 1))
                
                if nfcSupport {
                    LUIButton {
                        nfcReader.scan(infoMessage: String(format: "nfc_description".localized(), tracker.getName) )
                    } label: {
                        NavigationLinkLabel(imageName: "person.fill", text: "scan_nfc", backgroundColor: color, isNavLink: true)
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
}


struct Previews_TrackerInfoView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .AirTag)
        device.firstSeen = Date()
        device.lastSeen = Date()
        
        try? vc.save()
        
        return NavigationView {
            TrackerDetailView(tracker: device, bluetoothData: BluetoothTempData(identifier: UUID().uuidString))
                .environment(\.managedObjectContext, vc)
        }
    }
}

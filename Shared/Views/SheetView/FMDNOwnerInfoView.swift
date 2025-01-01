//
//  FMDNOwnerInfoView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 02.09.24.
//

import SwiftUI

struct FMDNOwnerInfoView: View {
    
    @ObservedObject var tracker: BaseDevice
    @State var status = ""
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    @State var url: URL? = nil
    @State var showAlert = false
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        
        BigButtonView(buttonHeight: Constants.BigButtonHeight, mainView: BigSymbolViewWithText(title: "more_trackerdetailview_owner_information", symbol: "person.fill", subtitle: getInstructions(), topPadding: 0), buttonView: FMDNLoadingView(tracker: tracker, bluetoothData: tracker.bluetoothTempData(), url: url), hideNavigationBar: false
        )
        .onReceive(timer) { _ in
            if url == nil {
                getOwnerInfo()
            }
        }
        .onAppear {
            getOwnerInfo()
        }

        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("more_trackerdetailview_owner_information_unavailable_title"), message: Text("more_trackerdetailview_owner_information_unavailable_description"), dismissButton: .default(Text("OK"), action: {
                presentationMode.wrappedValue.dismiss()
            }))
        })
    }
    
    func getInstructions() -> String {
        let name = tracker.getName
        let baseInstructions = "more_trackerdetailview_owner_information_fmdn"
        let stringPrefix = "more_trackerdetailview_owner_information_fmdn_"
        
        let manufacturers = ["Chipolo", "Pebblebee"]
        
        var allDescriptions = ""
        
        for manufacturer in manufacturers {
            let manufacturerDescription = "\n\n" + (stringPrefix + manufacturer.lowercased()).localized()
            
            if name.contains(manufacturer) {
                return String(format: baseInstructions.localized(), manufacturerDescription)
            }
            else {
                allDescriptions.append(manufacturerDescription)
            }
        }
        
     return String(format: baseInstructions.localized(), allDescriptions)
    }
    
    
    func getOwnerInfo() {
        
        if let id = tracker.currentBluetoothId {
            
            let getModelNameOpcode: UInt16 = 0x0404
            var opcode = getModelNameOpcode.littleEndian
            let data = Data(bytes: &opcode, count: MemoryLayout.size(ofValue: opcode))
            
            let request = BluetoothRequest.writeReadCharacteristic(deviceID: id, serviceID: GoogleConstants.soundService, characteristicID: GoogleConstants.soundCharacteristic!, data: data) { state, data in
                
                if state == .Success, let data = data {
                    
                    let hex = data.hexEncodedString().dropFirst(4)
                    
                    // Otherwise in wrong mode
                    if hex.count > 8 {
                        
                        if let url = URL(string: "https://spot-pa.googleapis.com/lookup?e=\(hex)") {
                            
                            
                            checkURLFor404(url: url) { isInvalid in
                                if isInvalid {
                                    showAlert = true
                                }
                                else {
                                    doubleVibration()
                                    withAnimation {
                                        self.url = url
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            BluetoothManager.sharedInstance.addRequest(request: request)
        }
    }

    func checkURLFor404(url: URL, completion: @escaping (Bool) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    completion(false)
                    return
                }
                
                if let htmlString = String(data: data, encoding: .utf8) {
                    let contains404 = htmlString.contains("404")
                    let containsError = htmlString.contains("error")
                    completion(contains404 && containsError)
                } else {
                    completion(false)
                }
            }
            
        
        task.resume()
    }
}


struct FMDNLoadingView: View {
    
    @ObservedObject var clock = Clock.sharedInstance

    @ObservedObject var tracker: BaseDevice
    @ObservedObject var bluetoothData: BluetoothTempData
    let url: URL?
    
    var body: some View {
        
        if let url = url {
            GrayButton(label: "more_trackerdetailview_owner_information_fmdn_show_owner_information") {
                openURL(url: url)
            }
        }
        else {
            
            HStack(spacing: 10) {
                Text(getStatus().localized())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.mainColor)
                
                ProgressView()
            }
            .padding(.horizontal)
        }
    }
    
    func getStatus() -> String {
        
        if deviceNotCurrentlyReachable(device: tracker, currentDate: clock.currentDate) {
            return "trying_connection"
        }
        
        return "more_trackerdetailview_owner_information_fmdn_connecting"
    }
}



struct Previews_TrackerFMDNInfoView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .Google)
        device.firstSeen = Date()
        device.lastSeen = Date()
        device.setName(name: "Chipolo Tracker")
        
        try? vc.save()
        
        return NavigationView {
            FMDNOwnerInfoView(tracker: device)
                .environment(\.managedObjectContext, vc)
             
        }
    }
}

//
//  FMDNDebugView.swift
//  AirGuard
//
//  Created by Leon Böttger on 23.09.24.
//

import SwiftUI
import CommonCrypto

@available(iOS 15.0, *)
struct FMDNDebugView: View {
    
    @ObservedObject var tracker: BaseDevice
    @StateObject var operationManager: FMDNOwnerOperations
    
    @AppStorage("fmdnKey") var ephemeralKey = ""
    @AppStorage("fmdnAccountKey") var accountKey = ""
    
    @State var trackerState: String? = nil
    
    init(tracker: BaseDevice) {
        self._operationManager = .init(wrappedValue: FMDNOwnerOperations(tracker: tracker))
        self.tracker = tracker
    }
    
    var body: some View {
        
        LUIButton {
            PersistenceController.sharedInstance.modifyDatabase { context in
                tracker.name = nil
                doubleVibration()
            }
            
        } label: {
            NavigationLinkLabel(imageName: "textformat", text: "Re-Retrieve Name", backgroundColor: .orange)
        }
        
        KeyInputField(label: "Ephemeral Key", operationManager: operationManager, key: $ephemeralKey, refreshKeys: refreshKeys)
        KeyInputField(label: "Account Key", operationManager: operationManager, key: $accountKey, refreshKeys: refreshKeys)
        
        if operationManager.didSetKeys {
            
            LUIButton {
                doubleVibration()
                operationManager.executeRingerOperation()
                
            } label: {
                NavigationLinkLabel(imageName: "waveform", text: "Ring Tracker", backgroundColor: .yellow)
            }
            
            
            LUIButton {
                doubleVibration()
                operationManager.executeEnableTrackingProtectionModeOperation()
                
            } label: {
                NavigationLinkLabel(imageName: "shield.fill", text: "Enable Tracking Protection Mode", backgroundColor: .green)
            }
            
            
            LUIButton {
                doubleVibration()
                operationManager.executeDisableTrackingProtectionModeOperation()
                
            } label: {
                NavigationLinkLabel(imageName: "shield.slash.fill", text: "Disable Tracking Protection Mode", backgroundColor: .red)
            }
            
            
            LUIButton {
                doubleVibration()
                operationManager.executeReadStateOperation { result in
                    withAnimation {
                        trackerState = result
                    }
                }
                
            } label: {
                NavigationLinkLabel(imageName: "questionmark", text: "Read Tracker State", backgroundColor: .blue)
            }
            
            if let state = trackerState {
                InfoAndCopyButton(label: "Tracker State", info: state)
            }
        }
    }
    
    func refreshKeys() {
        operationManager.generateKeys(ephemeralIdentityKeyHex: ephemeralKey, accountKeyHex: accountKey)
    }
}


@available(iOS 15.0, *)
struct KeyInputField: View {
    
    let label: String
    let operationManager: FMDNOwnerOperations
    @Binding var key: String
    
    let refreshKeys: () -> ()
    
    var body: some View {
        HStack {
            SettingsIcon(imageName: "key.fill", backgroundColor: .black)
            
            TextField("Enter \(label)", text: $key)
                .onSubmit {
                    refreshKeys()
                }
                .onAppear {
                    if !key.isEmpty {
                        refreshKeys()
                    }
                }
            
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray)
                .onTapGesture {
                    key = ""
                }
        }
        .frame(height: Constants.SettingsLabelHeight)
    }
}

//
//  SettingsView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 16.05.22.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var settings = Settings.sharedInstance
    
    @ObservedObject var notificationManager = NotificationManager.sharedInstance
    @ObservedObject var locationManager = LocationManager.sharedInstance
    
    @State var showPermissionSheet = false
    
#if DEBUG
    @State var showDebugOptions = true
#else
    @State var showDebugOptions = false
#endif
    
    @State var showStudyConsentDeclaration = false
    @State var requestingDeletionFailed = false
    
    let url = "https://tpe.seemoo.tu-darmstadt.de/privacy-policy.html"
    
    var body: some View {
        
        NavigationView {
            
            NavigationSubView(spacing: Constants.SettingsSectionSpacing) {
                
                
                if Constants.StudyIsActive {
                    CustomSection(header: "study_settings") {
                        
                        VStack(spacing: 0) {
                            
                            ZStack {
                                    Toggle(isOn: $settings.participateInStudy.animation()) {
                                        SettingsLabel(imageName: "waveform.path.ecg", text: "participate_study")
                                    }
                                    .opacity(settings.participateInStudy ? 1 : 0)
                                
   
                                    Button {
                                        showStudyConsentDeclaration = true
                                    } label: {
                                        NavigationLinkLabel(imageName: "waveform.path.ecg", text: "participate_study")
                                    }
                                    .opacity(settings.participateInStudy ? 0 : 1)
                                
                            }
                            
                            
                            if settings.participateInStudy {
                                
                                CustomDivider()
                                
                                Button {
                                    requestDataDeletion()
                                } label: {
                                    NavigationLinkLabel(imageName: "trash.fill", text: "delete_study_data", backgroundColor: .red, isNavLink: false)
                                }
                                .buttonStyle(.plain)
                                .alert(isPresented: $requestingDeletionFailed, content: {
                                    Alert(title: Text("deletion_failed"), message: Text("deletion_failed_message"), dismissButton: Alert.Button.cancel())
                                })
                            }
                        }
                        .sheet(isPresented: $showStudyConsentDeclaration) {
                            StudyOptInView { participate in
                                settings.participateInStudy = participate
                                showStudyConsentDeclaration = false
                            }
                        }
                    }
                }
                
                
                CustomSection(header: "background_scanning", footer: settings.securityLevel.description.localized()) {
                    Toggle(isOn: $settings.backgroundScanning) {
                        SettingsLabel(imageName: "text.magnifyingglass", text: "background_scanning", backgroundColor: .green)
                            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded({_ in showDebugOptions = true}))
                    }
                    .onChange(of: settings.backgroundScanning, perform: { newValue in
                        
                        // enabled background scanning
                        if(newValue) {
                            
                            UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
                                
                                if notificationSettings.authorizationStatus != .authorized || !locationManager.hasAlwaysPermission() {
                                    
                                    // show tutorial again to set permissions
                                    DispatchQueue.main.async {
                                        settings.backgroundScanning = false
                                        settings.tutorialCompleted = false
                                    }
                                    
                                }
                                else {
                                    locationManager.enableBackgroundLocationUpdate()
                                }
                            }
                        }
                        
                        // disabled background scanning
                        else {
                            locationManager.disableBackgroundLocationUpdate()
                        }
                    })
                    
                    
                    
                    NavigationLink {
                        DisableDevicesView()
                            .modifier(GoToRootModifier(view: .Settings))
                    } label: {
                        NavigationLinkLabel(imageName: "nosign", text: "manage_ignored_devices", backgroundColor: .orange)
                    }     .disabled(!settings.backgroundScanning)
                    
                    
                    CustomPickerLabel(selection: settings.securityLevel.name.localized(), backgroundColor: .yellow, description: "security_level", imageName: settings.securityLevel.image)
                        .disabled(!settings.backgroundScanning)
                    
                    
                    Picker("", selection: $settings.securityLevel) {
                        ForEach(SecurityLevel.allCases, id: \.self) { level in
                            
                            Text(level.name.localized())
                            
                                .id(level.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(height: Constants.SettingsLabelHeight)
                    .disabled(!settings.backgroundScanning)
                }
                

                
                CustomSection(header: "info") {
                    
                    NavigationLink {
                        InformationView()
                            .modifier(GoToRootModifier(view: .Settings))
                    } label: {
                        NavigationLinkLabel(imageName: "info", text: "information_and_contact", backgroundColor: Color.green)
                        
                    }
                    
                    if let url = URL(string: url) {
                        Link(destination: url, label: {
                            NavigationLinkLabel(imageName: "hand.raised.fill", text: "privacy_policy", backgroundColor: .red, isNavLink: false)
                        })
                    }
                }
                
                if(showDebugOptions) {
                    CustomSection(header: "Debug") {
                        NavigationLink {
                            DebugSettingsView()
                                .modifier(GoToRootModifier(view: .Settings))
                        } label: {
                            NavigationLinkLabel(imageName: "curlybraces", text: "Debug Settings")
                        }
                    }
                }
                
            }
            .navigationBarTitle("settings")
            
        } .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func requestDataDeletion() {
        // Get the UUID from the data study
        let studyUUID = UserDefaults.standard.string(forKey: "dataDonatorToken") ?? "No data transferred yet"
        
        // Construct a mailto url
        let mailContent = "I hereby request the deletion of the data gathered from the AirGuard application. My app identifier is \(studyUUID).\n\n Please get back to me when the deletion has been performed.".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        let subjectContent = "AirGuard Study Data Deletion Request".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        guard let mailContent, let subjectContent else {
            requestingDeletionFailed = true
            return
        }
        
        let mailtoURLstring = "mailto:aheinrich@seemoo.tu-darmstadt.de?subject=\(subjectContent)&body=\(mailContent)"
        
        guard let url = URL(string: mailtoURLstring) else {
            requestingDeletionFailed = true
            return
        }
        
        UIApplication.shared.open(url) { success in
            if success {
                withAnimation {
                    settings.participateInStudy = false
                }
            }else {
                requestingDeletionFailed = true
            }
        }
        
    }
}


struct Previews_SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

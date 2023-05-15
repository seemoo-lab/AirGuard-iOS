//
//  AppInfoView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.07.22.
//

import SwiftUI

struct InformationView: View {
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        
        NavigationSubView(spacing: Constants.SettingsSectionSpacing) {
            
            VStack(spacing: 0) {
                Button {
                    // Easter egg :)
                    mediumVibration()
                } label: {
                    ScanAnimation(size: 70, withBackground: true)
                        .cornerRadius(25)
                        .padding()
                }
                
                Text("airguard_ios")
                    .padding(.bottom, 3)
                Text("version".localized() + " \(getAppVersion())")
                    .opacity(0.5)
            }
            
            
            CustomSection(){
                
                Button(action: {
                    writeMail(to: "info@leonboettger.com")
                }) {
                    NavigationLinkLabel(imageName: "envelope.fill", text: "contact_developer", backgroundColor: Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)), isNavLink: false)
                }
            }
            
            CustomSection(header: "credits") {
                Button(action: {
                    writeMail(to: "info@leonboettger.com")
                }) {
                    NavigationLinkLabel(imageName: "curlybraces", text: "developer", backgroundColor: .green, isNavLink: false, status: "Leon Böttger")
                }
                
                Button(action: {
                    writeMail(to: "aheinrich@seemoo.tu-darmstadt.de")
                }) {
                    NavigationLinkLabel(imageName: "person.fill", text: "maintainer", backgroundColor: .orange, isNavLink: false, status: "Alexander Heinrich")
                }
            }
  
            
            CustomSection(header: "copyright") {
                Text("copyright_text")
                    .foregroundColor(Color("DarkBlue"))
                    .padding(.vertical)
            }
        }
        .navigationBarTitle("information")
    }
    
    func writeMail(to address: String) {
        if let url = URL(string: "mailto:\(address)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
}


/// Returns the app version number.
private func getAppVersion() -> String {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    return "\(appVersion ?? "unknown")"
}


struct Previews_AppInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InformationView()
        }
    }
}

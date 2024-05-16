//
//  AppInfoView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.07.22.
//

import SwiftUI

struct InformationView: View {
    
    @Environment(\.openURL) var openURL
    @State var showContactAlert = false
    @State var showedArticle: Article? = nil
    fileprivate let airGuardForOsString = String(format: "informationview_airguard_os".localized(), getOSName())
    fileprivate let airGuardVersionString = "version".localized() + " \(getAppVersion())"
    
    var body: some View {
        
        let showingArticleBinding = Binding {
            showedArticle != nil
        } set: { newValue in
            if !newValue {
                showedArticle = nil
            }
        }
        
        NavigationSubView(spacing: Constants.SettingsSectionSpacing) {
            
            VStack(spacing: 0) {
                LUIButton {
                    // Easter egg :)
                    lightVibration()
                } label: {
                    ScanAnimation(size: 60, withBackground: true)
                        .cornerRadius(25)
                        .padding()
                }
                
                Text(airGuardForOsString)
                    .padding(.bottom, 3)
                Text(airGuardVersionString)
                    .opacity(0.5)
            }
            .padding(.top)
            
            CustomSection {
                
                LUIButton(action: {
                    showContactAlert = true
                }) {
                    NavigationLinkLabel(imageName: "bubble.fill", text: "contact_developer", backgroundColor: Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)), isNavLink: false)
                }
                
                LUILink(destination: ArticleView(article: faqArticle)) {
                    NavigationLinkLabel(imageName: getFAQIcon(), text: "FAQ", backgroundColor: .purple, isNavLink: true)
                }
            }
            .actionSheet(isPresented: $showContactAlert) {
                ActionSheet(title: Text("informationview_contact_alert_title"), message: Text("informationview_contact_alert_description"), buttons: [
                    .default(Text("informationview_contact_alert_help_with_tracking")) { showedArticle = helpArticle },
                    .default(Text("informationview_contact_alert_read_faq")) { showedArticle = faqArticle },
                    .default(Text("contact_developer")) { writeMail(to: "airguard@seemoo.tu-darmstadt.de") },
                    .cancel()
                ])
            }
            
            CustomSection(header: "credits") {
                
                if let url = URL(string: "https://www.leonboettger.com") {
                    Link(destination: url, label: {
                        NavigationLinkLabel(imageName: "curlybraces", text: "developer_maintainer", backgroundColor: .green, isNavLink: false, status: "Leon Böttger")
                    })
                    .buttonStyle(LUIButtonStyle())
                }
                
                LUIButton(action: {
                    writeMail(to: "aheinrich@seemoo.tu-darmstadt.de")
                }) {
                    NavigationLinkLabel(imageName: "person.fill", text: "maintainer", backgroundColor: .orange, isNavLink: false, status: "Alexander Heinrich")
                }
            }
            
            LUILink(destination:
                        NavigationSubView {
                    CustomSection() {
                        Text("copyright_text")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.mainColor)
                            .padding(.vertical)
                    }
                    .navigationTitle("informationview_used_content")
            }, label: {
                Text("informationview_used_content")
                    .font(.system(size: 13))
                    .foregroundColor(.grayColor)
                    .underline(true)
            })
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .navigationBarTitle("", displayMode: .inline)
        .background(
            LUILink(destination: ZStack {
                    if let article = showedArticle {
                        ArticleView(article: article)
                    }
                }
            , isActive: showingArticleBinding, label: {
                EmptyView()
            })
        )
    }
    
    func writeMail(to address: String) {
        if let url = URL(string: "mailto:\(address)?subject=\(airGuardForOsString) \(airGuardVersionString)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
}


/// Navigation link icon for FAQ article
func getFAQIcon() -> String {
    if #available(iOS 16.0, *) {
        return "questionmark.bubble.fill"
    } else {
        return "questionmark"
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

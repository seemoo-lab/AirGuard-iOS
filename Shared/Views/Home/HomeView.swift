//
//  HomeView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 24.06.22.
//

import SwiftUI
import CoreData

struct HomeView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var bluetoothManager = BluetoothManager.sharedInstance
    @ObservedObject var locationManager = LocationManager.sharedInstance
    @ObservedObject var settings = Settings.sharedInstance
    
    init() {
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "DarkBlue")!]
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "DarkBlue")!]
    }
    
    var body: some View {
        
        NavigationView {
            GeometryReader { geo in

                NavigationSubView {
                    
                    if(!bluetoothManager.turnedOn && settings.mayCheckBluetooth) {
                        
                        CardView(backgroundColor: .red, title: getBluetoothProblemHeader(), titleSymbol: "shield.slash.fill", subView:
                                    AnyView(
                                        HStack {CardSubView(symbol: "exclamationmark.triangle.fill", text: getBluetoothProblemSubHeader())
                                        }))
                        .padding(.bottom, 10)
                        .onTapGesture {
                            openAppSettings()
                        }
                    }
                    else if(settings.backgroundScanning && !locationManager.hasAlwaysPermission()) {
                        
                        CardView(backgroundColor: .red, title: "background_location_paused", titleSymbol: "location.slash.fill", subView:
                                    AnyView(
                                        HStack {CardSubView(symbol: "exclamationmark.triangle.fill", text: "background_location_paused_description")
                                            
                                            Image(systemName: "chevron.right")
                                        }))
                        .padding(.bottom, 10)
                        .onTapGesture {
                            openAppSettings()
                        }
                    }
                    else {
                        RiskView()
                            .padding(.bottom, 10)
                    }
                    
                    ImageCardGroupHeader(name: "knowledge")
                    
                    ForEach(articles) { elem in
                        NavigationLink {
                            ArticleView(article: elem)
                        } label: {
                            NewImageCardView(card: elem.card)
                        }
                        .buttonStyle(PlainLinkStyle())
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitle("AirGuard")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct Previews_HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

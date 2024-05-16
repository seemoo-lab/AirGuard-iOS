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
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(.mainColor)]
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(.mainColor)]
    }
    
    var body: some View {
        
        NavigationView {
            
            GeometryReader { geo in
                
                NavigationSubView {
                    
                    if(!bluetoothManager.turnedOn && settings.mayCheckBluetooth) {
                        
                        CardView(backgroundColor: .red, title: getBluetoothProblemHeader(), titleSymbol: "shield.slash.fill") {
                            HStack {
                                CardSubView(symbol: "exclamationmark.triangle.fill", text: getBluetoothProblemSubHeader())
                            }
                        }
                        .padding(.bottom, 10)
                        .onTapGesture {
                            openAppSettings()
                        }
                    }
                    else if(settings.backgroundScanning && !locationManager.hasAlwaysPermission()) {
                        
                        CardView(backgroundColor: .red, title: "background_location_paused", titleSymbol: "location.slash.fill") {
                            HStack {
                                CardSubView(symbol: "exclamationmark.triangle.fill", text: "background_location_paused_description")
                                Image(systemName: "chevron.right")
                            }
                        }
                        .padding(.bottom, 10)
                        .onTapGesture {
                            LocationManager.sharedInstance.requestWhenInUse()
                            
                            runAfter(seconds: 1) {
                                LocationManager.sharedInstance.requestAlwaysUsage()
                            }
                            
                            runAfter(seconds: 0.3) {
                                openAppSettings()
                            }
                        }
                    }
                    else {
                        RiskView()
                            .padding(.bottom, 10)
                    }
                    
                    ImageCardGroupHeader(name: "knowledge")
                    
                    LazyVStack {
                        ForEach(articles) { elem in
                            LUILink(style: .Plain, destination: ArticleView(article: elem), label: {
                                NewImageCardView(card: elem.card)
                            })
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.horizontal, Constants.FormHorizontalPadding)
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

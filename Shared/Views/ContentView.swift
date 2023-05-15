//
//  ContentView.swift
//  Shared
//
//  Created by Leon Böttger on 15.04.22.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    
    @StateObject var settings = Settings.sharedInstance
    @StateObject var bluetoothManager = BluetoothManager.sharedInstance
    @StateObject var locationManager = LocationManager.sharedInstance
    @StateObject var reader = NFCReader.sharedInstance

    var body: some View {
        
        let showIntroduction = Binding(get: {return !settings.tutorialCompleted}, set: {val in
            DispatchQueue.main.async {
                settings.tutorialCompleted = !val
            }
        })
        
        TabView(selection: $settings.selectedTab) {
                
                HomeView()
                    .tabItem {
                        Label("home", systemImage: "house")
                    }
                    .tag(Tabs.HomeView)

                    ManualScanningView()
                        .tabItem {
                            Label("manual_scan", systemImage: "magnifyingglass")
                        }
                        .tag(Tabs.ManualScan)
                
                SettingsView()
                    .tabItem {
                        Label("settings", systemImage: "gear")
                    }
                    .tag(Tabs.Settings)
            }
            .sheet(isPresented: $settings.showSheet) {
                
                if let tracker = settings.selectedTracker {

                    NavigationView {
                        TrackerDetailView(tracker: tracker, bluetoothData: tracker.bluetoothTempData())
                            .navigationBarItems(trailing: Button(action: {
                                settings.showSheet = false
                            }, label: {Text("done").bold().font(.system(size: 17))}))
                    }
                }
            }
             
        .fullScreenCover(isPresented: showIntroduction, content: {
            if(!settings.appLaunchedBefore) {
                IntroductionView()
            }
            else {
                NavigationView {
                    NotificationPermissionView()
                }
            }
        })
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

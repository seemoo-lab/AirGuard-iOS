//
//  AirGuardApp.swift
//  Shared
//
//  Created by Leon Böttger on 15.04.22.
//

import SwiftUI

@main
struct AirGuardApp: App {
    
    private let persistenceController = PersistenceController.sharedInstance
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject var settings = Settings.sharedInstance
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appDelegate)
                .onChange(of: scenePhase) { newPhase in
                    
                    if newPhase == .active {
                        settings.isBackground = false
                        
                    } else if newPhase == .inactive  || newPhase == .background {
                        settings.isBackground = true
                        
                    }
                }
                .onAppear(perform: {
                    settings.isBackground = scenePhase != .active
                })
        }
    }
}

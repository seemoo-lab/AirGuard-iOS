//
//  AirGuardApp.swift
//  Shared
//
//  Created by Leon Böttger on 15.04.22.
//

import SwiftUI
import StoreKit

@main
struct AirGuardApp: App {
    
    private let persistenceController = PersistenceController.sharedInstance
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject var settings = Settings.sharedInstance
    @AppStorage("appLaunches") private var appLaunches = 0
    @AppStorage("minLaunchesForReview") private var minLaunchesForReview = 20
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appDelegate)
                .onChange(of: scenePhase) { newPhase in
                    
                    if newPhase == .active {
                        settings.isBackground = false
                        appAppeared()
                        
                    } else if newPhase == .inactive  || newPhase == .background {
                        settings.isBackground = true
                        
                    }
                }
                .onAppear(perform: {
                    settings.isBackground = scenePhase != .active
                })
        }
    }
    
    func appAppeared() {
        
        appLaunches += 1
        
        log("App launched \(appLaunches) times!")
        
#if !os(watchOS) && !os(tvOS) && !targetEnvironment(simulator)
        if(appLaunches >= minLaunchesForReview) {
            log("Requesting Review")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                    minLaunchesForReview += 50
                }
                else {
                    log("Error Requesting Review!")
                }
            }
        }
#endif
    }
}

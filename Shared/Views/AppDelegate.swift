//
//  BackgroundAppRefresh.swift
//  AirGuard
//
//  Created by Leon Böttger on 26.05.22.
//

import Foundation
import SwiftUI
import BackgroundTasks

/// Custom `UIApplicationDelegate` class
class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    
    var notificationManager = NotificationManager.sharedInstance
    var window: UIWindow?
    var statisticsController = SendStatisticsController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        log("Finished launching")
        
        // Send stats
        Task {
            do {
                try await statisticsController.sendStats()
                log("Finished donating data")
            }catch {
                log("Failed donating data \(error.localizedDescription)")
            }
            await statisticsController.scheduleDataDonation()
        }
        
        #if DEBUG
        evaluateDebugLaunchArguments()
        #endif 
        
        return true
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background tasks
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "de.tu-darmstadt.seemoo.airguard.donateData", using: nil) { task in
            Task {
                await self.statisticsController.handleBackgroundTaskDataDonation(task: task as! BGAppRefreshTask)
            }
        }
        return true
    }
}

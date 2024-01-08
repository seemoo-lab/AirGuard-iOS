//
//  Settings.swift
//  AirGuard
//
//  Created by Leon Böttger on 02.05.22.
//

import Foundation
import CoreBluetooth
import UIKit
import SwiftUI


/// Stores user settings
class Settings: ObservableObject {
    
    /// The shared instance
    static let sharedInstance = Settings()
    
    /// Private initializer
    private init() {

        // initial launch of app
        if(!appLaunchedBefore) {

            // Set default user default keys
            backgroundScanning = true
        }
    }
    
    /// The security level of the app.
    @Published var securityLevel: SecurityLevel = (SecurityLevel(rawValue: userDefaults.string(forKey: UserDefaultKeys.securityLevel.rawValue) ?? SecurityLevel.Normal.rawValue) ?? SecurityLevel.Normal) {
        didSet {userDefaults.set(securityLevel.rawValue, forKey: UserDefaultKeys.securityLevel.rawValue)}}
    
    
    /// Shows that the app is in debug mode.
    @Published var debugMode = userDefaults.bool(forKey: UserDefaultKeys.debugMode.rawValue) {
        didSet {userDefaults.set(debugMode, forKey: UserDefaultKeys.debugMode.rawValue)}}
    
    
    /// Sends notifications for debug.
    @Published var debugPush = userDefaults.bool(forKey: UserDefaultKeys.debugPush.rawValue) {
        didSet {userDefaults.set(debugPush, forKey: UserDefaultKeys.debugPush.rawValue)}}
    
    
    /// Shows that the user agreed to participate in the study.
    @Published var participateInStudy = userDefaults.bool(forKey: UserDefaultKeys.participateInStudy.rawValue) {
        didSet {userDefaults.set(participateInStudy, forKey: UserDefaultKeys.participateInStudy.rawValue)}}
    
    
    /// Shows that the app launched before AND the tutorial was completed.
    @Published var appLaunchedBefore = userDefaults.bool(forKey: UserDefaultKeys.appLaunchedBefore.rawValue) {
        didSet {userDefaults.set(appLaunchedBefore, forKey: UserDefaultKeys.appLaunchedBefore.rawValue)}}
    
    /// Shows that the app launched before AND the tutorial was completed.
    @Published var askedForStudyParticipation = userDefaults.bool(forKey: UserDefaultKeys.studyParticipationRequested.rawValue) {
        didSet {userDefaults.set(askedForStudyParticipation, forKey: UserDefaultKeys.studyParticipationRequested.rawValue)}}
    
    #if !targetEnvironment(simulator)
    /// False if the app tutorial is active.
    @Published var tutorialCompleted = userDefaults.bool(forKey: UserDefaultKeys.tutorialCompleted.rawValue) {
        didSet {
            userDefaults.set(tutorialCompleted, forKey: UserDefaultKeys.tutorialCompleted.rawValue)
            
            /// The user completed the tutorial for the first time
            if tutorialCompleted && !appLaunchedBefore {
                appLaunchedBefore = true
                startBluetooth()
            }
        }}
    #else
    /// False if the app tutorial is active.
    @Published var tutorialCompleted = true
    #endif
    
    
    /// Shows if the user agreed that the app can scan in the background.
    @Published var backgroundScanning = userDefaults.bool(forKey: UserDefaultKeys.backgroundScanning.rawValue) {
        didSet {userDefaults.set(backgroundScanning, forKey: UserDefaultKeys.backgroundScanning.rawValue)}}

    
#if !BUILDING_FOR_APP_EXTENSION
    /// Shows if the app is in background or inactive.
    @Published var isBackground = true {
        didSet {
            if(isBackground != oldValue) {
                log("set background: \(isBackground)")
                
                if(isBackground) {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.mayCheckBluetooth = false
                        }
                    }
                }
                
                //foreground
                else {
                    
                    lastAppStart = Date()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            self.mayCheckBluetooth = true
                        }
                    }
                }
                
                startBluetooth()
            }
        }
    }
#else
    /// Shows if the app is in background or inactive.
    @Published var isBackground = false // for the widget, we do not care
#endif
    
    /// The last time the app was launched in the foreground
    @Published var lastAppStart = Date()
    
    /// Shows if the app is currently in foreground and the bluetooth manager had enough time to start up. Then the status of the bluetooth manager can be checked and a notification can be shown if Bluetooth if off.
    @Published var mayCheckBluetooth = false
    
    /// The selected tracker for the sheet view. Needs to be fetched from MAIN CONTEXT!
    @Published var selectedTracker: BaseDevice? = nil
    
    /// Shows if sheet view is active.
    @Published var showSheet = false {
        didSet {
            
            // Make sure fast scan is disabled when returning to Manual Scan
            if !showSheet, BluetoothManager.sharedInstance.isFastScanning() {
                BluetoothManager.sharedInstance.disableFastScan()
            }
        }
    }
    
    /// The selected tab.
    @Published var selectedTab = Tabs.HomeView {
        didSet {
            
            lightVibration()
            
            // Tapped twice on the same tab
            if(oldValue == selectedTab) {
                goToRootTab = selectedTab
                goToRoot.toggle()
            }
            // Went to another tab
            else {
                goToRootTab = nil
            }
        }
    }
    
    /// Changes its value if the same tab is tapped twice.
    @Published var goToRoot = false
    
    /// If goToRoot changes, this variable shows which tab should go back to its root page.
    @Published var goToRootTab: Tabs? = nil
    
}


/// Starts the Bluetooth scan.
func startBluetooth() {
    
    // only start if app launched before, to delay permission popup
    if(Settings.sharedInstance.tutorialCompleted) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            // create a new central manager if no one exists
            BluetoothManager.sharedInstance.startCentralManager()
            
            if !Settings.sharedInstance.isBackground {
                // cancels connections. Allows for faster AirTag detection
                BluetoothManager.sharedInstance.cancelAllConnections()
            }
            
            // toggle scan from background/foreground or start it
            BluetoothManager.sharedInstance.startScan()
        }
    }
}


/// The primary user defaults of the app
var userDefaults: UserDefaults {
    
    // Take app group
    if let userDefaults = UserDefaults(suiteName: AppGroup.appGroupName) {
        return userDefaults
    }
    
    // Should not happen, but...
    return UserDefaults.standard
}


/// Determines the security level of the background scanning.
enum SecurityLevel: String, CaseIterable {
    
    // Do not change - name used for UserDefaults!
    case Low
    case Normal
    case High
    
    var name: String {
        switch self {
        case .Low:
            return "low"
        case .Normal:
            return "normal"
        case .High:
            return "high"
        }
    }
    
    var description: String {
        switch self {
        case .Low:
            return "security_level_low_description"
        case .Normal:
            return "security_level_normal_description"
        case .High:
            return "security_level_high_description"
        }
    }
    
    var image: String {
        switch self {
        case .Low:
            return "shield"
        case .Normal:
            return "shield.lefthalf.fill"
        case .High:
            return "shield.fill"
        }
    }
}


/// String keys for user default settings
enum UserDefaultKeys: String {
    case debugMode
    case debugPush
    case stoppedNotificationID
    case stoppedLocationID
    case lastMultipleSmartTagsNotification
    case notificationCounter
    case participateInStudy
    case tutorialCompleted
    case backgroundScanning
    case appLaunchedBefore
    case securityLevel
    case studyParticipationRequested
    case surveyNotificationSent
}


/// Tabs of the app. Used for going to root view if tapped tab twice
enum Tabs {
    case HomeView
    case ManualScan
    case Settings
}

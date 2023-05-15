//
//  NotificationManager.swift
//  AirGuard
//
//  Created by Leon Böttger on 04.05.22.
//

import UserNotifications
import UIKit

/// Handles delivery of local notifications.
class NotificationManager: ObservableObject {
    
    /// The shared instance.
    static var sharedInstance = NotificationManager()
    
    /// The initializer.
    private init() { }
    
    /// The ID of the notification which tells the user that the scanning has stopped.`nil` if no such notification exists.
    @Published var stoppedNotificationID: String? = UserDefaults.standard.string(forKey: UserDefaultKeys.stoppedNotificationID.rawValue) {
        didSet {UserDefaults.standard.set(stoppedNotificationID, forKey: UserDefaultKeys.stoppedNotificationID.rawValue)}}
    
    
    /// The ID of the notification which tells the user that the background location was disabled. `nil` if no such notification exists.
    @Published var stoppedLocationID: String? = UserDefaults.standard.string(forKey: UserDefaultKeys.stoppedLocationID.rawValue) {
        didSet {UserDefaults.standard.set(stoppedLocationID, forKey: UserDefaultKeys.stoppedLocationID.rawValue)}}
    
    
    /// References to other objects
    private let persistenceController = PersistenceController.sharedInstance
    
    
    /// Requests notification permission from user.
    func requestNotificationPermission(callback: @escaping (Bool) -> Void) {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                log("All set!")
                DispatchQueue.main.async {
                    callback(true)
                }
                return
            } else if let error = error {
                log(error.localizedDescription)
            }
            DispatchQueue.main.async {
                callback(false)
            }
        }
    }
    
    
    /// Queues notification that manager has stopped. Delayed by 10 minutes.
    func sendManagerStoppedNotification() {
            
        DispatchQueue.main.async { [self] in
            if stoppedNotificationID == nil && Settings.sharedInstance.isBackground {
                
                log("Sending manager stopped notification...")
                
                let id = UUID().uuidString
                self.stoppedNotificationID = id
                

                pushNotification(title: "background_scanning_paused".localized(), subtitle: "background_scanning_paused_description".localized(), identifier: id, delay: minutesToSeconds(minutes: 10)) // give manager 10min to restart, else we send the notification
                
            }
        }
    }
    
    /// Sends notification that location access was disabled.
    func sendLocationStoppedNotification() {
            

            if stoppedLocationID == nil && Settings.sharedInstance.isBackground {
                
                let id = UUID().uuidString
                stoppedLocationID = id
                
                pushNotification(title: "background_location_paused".localized(), subtitle: "background_location_paused_description".localized(), identifier: id)
            }
        
    }
    
    
    /// Removes the notification with the given identifier from Notification Center or if still pending, from the queue
    func removeNotification(withIdentifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [withIdentifier])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [withIdentifier])
    }
    
    
    /// Removes any manager stopped notifications, from Notification Center or from notification pending queue
    func removeManagerStoppedNotification() {
        
        DispatchQueue.main.async { [self] in
            if let stoppedNotificationID = stoppedNotificationID {
                
                log("Removing manager stopped notification...")
                
                removeNotification(withIdentifier: stoppedNotificationID)
                
                self.stoppedNotificationID = nil
            }
        }
    }
    
    
    /// Removes any location stopped notifications, from Notification Center or from notification pending queue
    func removeLocationStoppedNotification() {
            
            if let stoppedLocationID = stoppedLocationID {
                removeNotification(withIdentifier: stoppedLocationID)
                self.stoppedLocationID = nil
            }
    }
    
    
    /// Delivers a local notification if debug mode is on.
    func debugPushNotification(title: String, subtitle: String) {
        
        if Settings.sharedInstance.debugPush {
            pushNotification(title: title, subtitle: subtitle, logging: false)
        }
    }
    
    
    /// Delivers a local notification.
    func pushNotification(title: String, subtitle: String, identifier: String = UUID().uuidString, userInfo: [String : String?] = [:], delay: Double = 0.01, logging: Bool = true) {
        
        if(logging) {
            log("New Notification added: \(title) \(subtitle)")
        }
        
        let content = UNMutableNotificationContent()
        
#if !BUILDING_FOR_APP_EXTENSION
        content.title = title
#else
        content.title = "[WIDGET]" + title
#endif
        
        content.body = subtitle
        content.sound = UNNotificationSound.default
        
        for key in userInfo.keys {
            if let value = userInfo[key], let value = value {
                content.userInfo.updateValue(value, forKey: key)
            }
        }
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // choose a random identifier
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // add notification request
        UNUserNotificationCenter.current().add(request)
    }
}


/// Extension of UserDefaults to store date.
extension UserDefaults {
    func set(date: Date?, forKey key: String){
        self.set(date, forKey: key)
    }
    
    func date(forKey key: String) -> Date? {
        return self.value(forKey: key) as? Date
    }
}

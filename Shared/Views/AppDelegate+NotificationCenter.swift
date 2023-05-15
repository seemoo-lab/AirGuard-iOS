//
//  AppDelegate+NotificationCenter.swift
//  AirGuard
//
//  Created by Leon Böttger on 04.06.22.
//

import Foundation
import UserNotifications
import CoreData

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// enables notification in-app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    
    /// handles tap on notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        PersistenceController.sharedInstance.modifyDatabase { context in
            
            /// Get corresponding notification id in database
            if let notificationID = userInfo[UserInfoKeys.TrackerNotificationIdentifier.rawValue] as? String {
                
                /// get tracker notification and update `tapped` field
                if let notification = fetchNotifications(withPredicate: NSPredicate(format: "identifier == %@", notificationID), withLimit: 1, context: context).first {
                    
                    log("Tapped on notification: \(response.notification.request.content.title)")
                    notification.tapped = true
                }
            }
            
            /// Get corresponding tracker and open sheet overview for it
            if let trackerID = userInfo[UserInfoKeys.TrackerIdentifier.rawValue] as? String {
                
                // Fetch the device on main thread!
                if let device = fetchDeviceWithUniqueID(uuid: trackerID, context: context) {
                    
                    log("Tapped on notification - ID of tracker known")
                    
                    DispatchQueue.main.async {
                        openSheet(withDevice: device)
                    }
                }
            }
        }
        
        
        // we are done
        completionHandler()
    }
}

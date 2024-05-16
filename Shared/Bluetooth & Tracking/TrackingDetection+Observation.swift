//
//  TrackingDetection+Observation.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 17.01.24.
//

import SwiftUI
import CoreData

fileprivate var notificationManager = NotificationManager.sharedInstance

extension TrackingDetection {
    
    /// Sends the a notification, if the user observed the tracker and it was seen
    func tryToRequestObservingTrackerNotification(forTracker: BaseDevice, context: NSManagedObjectContext) {
        
        // User wanted to observe tracker
        if(forTracker.observingStartDate ?? Date.distantFuture < Date()) {
            
            stopObservingTracker(tracker: forTracker, context: context)
            
            let name = forTracker.getName
            let uniqueID = forTracker.uniqueId
            
            DispatchQueue.global(qos: .utility).async {
                notificationManager.pushNotification(title: "update_tracker_observing".localized(),
                                                          subtitle: String(format: "tracker_still_follows_you_description".localized(), arguments: [name]),
                                                          userInfo:
                                                            [UserInfoKeys.TrackerIdentifier.rawValue: uniqueID])
            }
        }
    }
    
    
    /// User started to observe tracker manually. The argument context is only required to signalize that this method must only be called from `PersistenceController.sharedInstance.modifyDatabase`
    func startObservingTracker(tracker: BaseDevice, context: NSManagedObjectContext) {
        
        // after one hour, we look if the tracker is still nearby
        let delayUntilObserving: Double = hoursToSeconds(hours: 1)
        
        tracker.observingStartDate = Date().advanced(by: delayUntilObserving)
        
        let name = tracker.getName
        let notificationID = self.getObservingNotificationIdentifier(tracker: tracker)
        let uniqueID = tracker.uniqueId
        
        DispatchQueue.global(qos: .utility).async {
            
            // after 1h 20min, we send a notification to indicate that the tracker is no longer nearby. Notification gets cancelled if detected within 20min.
            let delayUntilNotification: Double = delayUntilObserving + minutesToSeconds(minutes: 20)
            
            NotificationManager.sharedInstance.pushNotification(title: "update_tracker_observing".localized(),
                                                                subtitle: String(format: "observed_tracker_not_found".localized(), name),
                                                                identifier: notificationID,
                                                                userInfo:
                                                                    [UserInfoKeys.TrackerIdentifier.rawValue: uniqueID],
                                                                delay: delayUntilNotification)
        }
    }
    
    
    /// User stopped to observe tracker manually or tracker was detected. The argument context is only required to signalize that this method must be called from within `PersistenceController.sharedInstance.modifyDatabase`
    func stopObservingTracker(tracker: BaseDevice, context: NSManagedObjectContext) {
        
        tracker.observingStartDate = nil
        
        let identifier = self.getObservingNotificationIdentifier(tracker: tracker)
        
        DispatchQueue.global(qos: .utility).async {
            NotificationManager.sharedInstance.removeNotification(withIdentifier: identifier)
        }
    }
    
    
    /// Gets the Identifier for the `Not Found Anymore` notification
    func getObservingNotificationIdentifier(tracker: BaseDevice) -> String {
        if let uniqueID = tracker.uniqueId {
            return uniqueID + "Observation"
        }
        return ""
    }
    
}

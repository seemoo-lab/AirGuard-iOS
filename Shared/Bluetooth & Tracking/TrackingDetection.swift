//
//  TrackingDetection.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 16.05.22.
//

import Foundation
import CoreLocation
import CoreData

/// Checks if a user might have been tracked by a given tracker.
class TrackingDetection: ObservableObject {
    
    /// specifies the minimum time in minutes a tracker has to be nearby before a notification can be sent
    static var minimumTrackingTime: Double {
        switch Settings.sharedInstance.securityLevel {
            
        case .Low:
            return minutesToSeconds(minutes: 120)
        case .Normal:
            return minutesToSeconds(minutes: 60)
        case .High:
            return minutesToSeconds(minutes: 30)
        }
    }
    
    /// specifies the minimum distance in meters the three locations have to be away from each other before a notification can be sent
    static let minLocationDist: Double = 200
    
    /// specifies the minimum distance in meters any two of the three locations need to be away from each other before a notification can be sent
    static let minTrackingDist: Double = minLocationDist*2

    /// specifies how often a detection event has to be occurred before a notification can be sent
    static let minimumDetectionEvents = 3
    
    /// specifies in seconds how often notification to the same tracker are allowed to be sent
    static let secondsUntilAnotherNotification: Double = hoursToSeconds(hours: 8)
    
    /// Subtract x seconds from every 'minimum tracking time'. The reason for this is that Tiles and SmartTags we get CoreBluetooth updates for already seen trackers every 15 minutes. If we would not subtract the buffer Value from ex. 30min, it could happen that we could send a notification at 45m, since the 15 minutes are not always exact -> if delivered early, 30mins might not be reached
    static let trackingTimeBuffer: Double = 60
    
    /// References to other objects
    private let persistenceController = PersistenceController.sharedInstance
    private let locationManager = LocationManager.sharedInstance
    private let settings = Settings.sharedInstance
    private var notificationManager = NotificationManager.sharedInstance
    
    /// The initializer
    private init() {}
    
    /// The shared instance.
    static let sharedInstance = TrackingDetection()
    
    
    /// Checks if the user might have been tracked with the given device
    func checkIfTracked(device: BaseDevice, context: NSManagedObjectContext) {
        if device.isTracker, !device.ignore, !device.getType.getIgnore() {
            
            /// Already sent a notification -> we do not check for locations, time etc.
            if alreadyReceivedNotification(forDevice: device) {
                
                tryToRequestTrackerNotification(forTracker: device, context: context)
            }
            
            /// Not received notification yet
            else if isTrackingForEnoughTime(baseDevice: device), let detections = device.detectionEvents?.array as? [DetectionEvent], detections.last?.connectionStatus != ConnectionStatus.OwnerConnected.rawValue {
                
                // Only use non-owner connected detections of last 14 days to make computation more efficient and to reduce false notifications
                var detectionsLast14Days = [DetectionEvent]()
                
                for detection in detections.reversed() {
                    
                    if let time = detection.time {
                        if(time.isOlderThan(seconds: daysToSeconds(days: 14))) {
                            break
                        }
                        else {
                            if detection.connectionStatus != ConnectionStatus.OwnerConnected.rawValue {
                                detectionsLast14Days.insert(detection, at: 0) // preserve order
                            }
                        }
                    }
                }
                
                if hasEnoughDetectionEvents(baseDevice: device, detections: detectionsLast14Days),
                   (!locationManager.hasAlwaysPermission() || hasMinDetectionDistance(baseDevice: device, detections: detectionsLast14Days)) {
                    
                    tryToRequestTrackerNotification(forTracker: device, context: context)
                }
            }
        }
        
        /// User wanted to observe tracker
        if device.isTracker {
            self.tryToRequestObservingTrackerNotification(forTracker: device, context: context)
        }
    }
    
    
    /// Checks if the tracker has been detected multiple times
    func hasEnoughDetectionEvents(baseDevice: BaseDevice, detections: [DetectionEvent]) -> Bool {
        return detections.count >= TrackingDetection.minimumDetectionEvents
    }
    
    
    /// Gets a list of detection events and checks if the user is being tracked for the minimum amount of time before a notification is sent.
    func isTrackingForEnoughTime(baseDevice: BaseDevice) -> Bool {
        
        if let detections = baseDevice.detectionEvents?.array as? [DetectionEvent] {
            
            if let first = detections.first, let last = detections.last, let firstDate = first.time, let lastDate = last.time,
               firstDate.distance(to: lastDate) >= (baseDevice.getType.constants.minTrackingTime - TrackingDetection.trackingTimeBuffer) {
                
                return true
            }
        }
        
        return false
    }
    
    
    /// Checks if any detections meet the minimal distance requirement
    private func hasMinDetectionDistance(baseDevice: BaseDevice, detections: [DetectionEvent]) -> Bool {
        
        // Removes duplicate locations
        let withoutDuplicates = Set(detections.compactMap({$0.location}))
        
        // If fewer than three locations, the minimum requirement is not reached
        if withoutDuplicates.count < 3 {
            return false
        }
        
        // generate array with CLLocation for easier distance comparison
        let locations = Array(withoutDuplicates).map({CLLocation(latitude: $0.latitude, longitude: $0.longitude)})
        
        
        // ----- check if there are 3 locations which are all different from each other and all locations have the minimum distance -----
        
        
        // Check all locations
        for a in 0..<locations.count {
            
            for b in a+1..<locations.count {
                
                for c in b+1..<locations.count {
                    
                    let loc1 = locations[a]
                    let loc2 = locations[b]
                    let loc3 = locations[c]
                    
                    let dist12 = loc1.distance(from: loc2)
                    let dist23 = loc2.distance(from: loc3)
                    let dist31 = loc3.distance(from: loc1)
                    
                    // check for minimum distance requirement
                    let fulfillsRequirement = dist12 >= TrackingDetection.minLocationDist &&
                    dist23 >= TrackingDetection.minLocationDist &&
                    dist31 >= TrackingDetection.minLocationDist &&
                    
                    (dist12 >= TrackingDetection.minTrackingDist ||
                     dist23 >= TrackingDetection.minTrackingDist ||
                     dist31 >= TrackingDetection.minTrackingDist)
                    
                    // if requirement is true, return true. Otherwise we continue iterating.
                    if fulfillsRequirement {
                        return true
                    }
                }
            }
        }
        
        // 3 locations with requirement not found
        return false
    }
    
    
    /// Returns the date of the last notification for a given device
    func getDateOfLastNotification(device: BaseDevice) -> Date? {
        if let notifications = device.notifications?.array as? [TrackerNotification] {
            return notifications.last?.time
        }
        return nil
    }
    

    /// Returns `true` if a notification was sent for the tracker already, else `false`
    func alreadyReceivedNotification(forDevice: BaseDevice) -> Bool {
        
        if let notifications = forDevice.notifications?.array as? [TrackerNotification] {
            return notifications.count > 0
        }
        return false
    }
    
    
    /// Sends the user a notification if he/she has never received a notification for the tracker, or if the time to the last one is has surpassed a threshold
    func tryToRequestTrackerNotification(forTracker: BaseDevice, context: NSManagedObjectContext) {
        
        if let notifications = forTracker.notifications?.array as? [TrackerNotification], let firstSeen = forTracker.firstSeen {
            
            if(notifications.last?.time?.timeIntervalSinceNow ?? -.infinity < -TrackingDetection.secondsUntilAnotherNotification) {
                
                // crete new notification ID
                let notificationID = UUID()
                
                // create notification in database
                let notification = TrackerNotification(context: context)
                notification.time = Date()
                notification.baseDevice = forTracker
                notification.identifier = notificationID
                
                // if we already sent a automatic notification, there is no need to send another (tracker observation) one
                self.stopObservingTracker(tracker: forTracker, context: context)
                
                let name = forTracker.getName
                let uniqueID = forTracker.uniqueId
                
                DispatchQueue.global(qos: .utility).async {
                    // arguments for notification
                    let arguments: [String] = [name, getSimpleSecondsText(seconds: -Int(firstSeen.timeIntervalSinceNow)).lowercaseFirstLetter()]
                    
                    // send local notification to user
                    self.notificationManager.pushNotification(title: "tracker_follows_you".localized(),
                                                              subtitle: String(format: "tracker_follows_you_description".localized(), arguments: arguments),
                                                              userInfo:
                                                                [UserInfoKeys.TrackerIdentifier.rawValue: uniqueID,
                                                                 UserInfoKeys.TrackerNotificationIdentifier.rawValue: notificationID.uuidString])
                }
            }
        }
    }
    
    
    /// Sends the a notification, if the user observed the tracker and it was seen
    func tryToRequestObservingTrackerNotification(forTracker: BaseDevice, context: NSManagedObjectContext) {
        
        // User wanted to observe tracker
        if(forTracker.observingStartDate ?? Date.distantFuture < Date()) {
            
            stopObservingTracker(tracker: forTracker, context: context)
            
            let name = forTracker.getName
            let uniqueID = forTracker.uniqueId
            
            DispatchQueue.global(qos: .utility).async {
                self.notificationManager.pushNotification(title: "update_tracker_observing".localized(),
                                                          subtitle: String(format: "tracker_still_follows_you_description".localized(), arguments: [name]),
                                                          userInfo:
                                                            [UserInfoKeys.TrackerIdentifier.rawValue: uniqueID])
            }
        }
    }
    
    
    /// User started to observe tracker manually. The argument context is only required to signalize that this method must be called from withing `PersistenceController.sharedInstance.modifyDatabase`
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
    
    
    /// User stopped to observe tracker manually or tracker was detected. The argument context is only required to signalize that this method must be called from withing `PersistenceController.sharedInstance.modifyDatabase`
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
    
    
    /// Adds a detection event for the given device and stores it in the database. Important: the BaseDevice needs to be saved already!
    func addDetectionEvent(toDevice: BaseDevice, bluetoothData: BluetoothTempData, context: NSManagedObjectContext) {
        
        if let lastDetectionEvent = toDevice.detectionEvents?.array.last as? DetectionEvent {
            if let previousSeen = lastDetectionEvent.time {
                
                // do not record too many detection events
                if(!previousSeen.isOlderThan(seconds: minutesToSeconds(minutes: 3))) {
                    return
                }
            }
        }
        
        let deviceID = toDevice.objectID
        
        // store important data already, since location may be delayed
        let connectionStatus = toDevice.getType.constants.connectionStatus(advertisementData: bluetoothData.advertisementData_background).rawValue
        let time = toDevice.lastSeen
        let rssi = (bluetoothData.rssi_background) as NSNumber
        
        self.locationManager.getNewLocation() { [self] location, context in // location may be nil
            
            if let toDevice = context.object(with: deviceID) as? BaseDevice {
                
                if(toDevice.getType != DeviceType.Unknown) {
                    log("Added Detection Event & Location to \(toDevice.getName)")
                }
                
                let detectionEvent = DetectionEvent(context: context)
                
                detectionEvent.connectionStatus = connectionStatus
                detectionEvent.time = time
                detectionEvent.rssi = rssi
                detectionEvent.baseDevice = toDevice

                detectionEvent.location = location
                
                self.checkIfTracked(device: toDevice, context: context)
            }
        }
    }
}


/// Strings used for UserInfo in LocalNotifications.
enum UserInfoKeys: String {
    
    // The unique ID of a tracker
    case TrackerIdentifier
    
    // The unique ID of a automatic background tracking notification
    case TrackerNotificationIdentifier
}

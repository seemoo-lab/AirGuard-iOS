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
    
    /// specifies in seconds how often notifications to the same tracker are allowed to be sent
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
            
            var lastNotificationDate = Date.distantPast
            
            /// Check when last notification was sent
            if let notifications = device.notifications?.array as? [TrackerNotification], 
                let lastNotification = notifications.last,
                let date = lastNotification.time {
                
                lastNotificationDate = date
            }

            if let detections = device.detectionEvents?.array as? [DetectionEvent],
               
                /// Early abortion - if not tracking for enough time or tracker is not in tracking mode, we dont send any notification
               isTrackingForEnoughTime(baseDevice: device, detections: detections),
               isTrackerInTrackingMode(for: detections.last) {
                
                /// Only use non-owner connected detections of last `trackingEventsSince` seconds
                /// Also only consider detections after last notification
                /// To make computation more efficient and to reduce false notifications
                var relevantDetectionEvents = [DetectionEvent]()
                
                /// Check most recent detections first
                for detection in detections.reversed() {
                    
                    if let time = detection.time {
                        
                        /// If the detection event is older than X hours, we do not conisder it anymore
                        if(time.isOlderThan(seconds: device.getType.constants.trackingEventsSince)
                           
                           /// We only consider detection events which are sent after the last notification (new events)
                           || time <= lastNotificationDate) {
                            
                            /// Quit the for loop (break because we transverse the detections in reverse)
                            break
                        }
                        else {
                            if isTrackerInTrackingMode(for: detection) {
                                relevantDetectionEvents.insert(detection, at: 0) // preserve order (oldest first)
                            }
                        }
                    }
                }
                
                /// Check `isTrackingForEnoughTime` with the filtered detections again. That's because when a notification has been sent, we only want to check the new detections, after this notification. We check `isTrackingForEnoughTime` twice. The first call is to filter out a lot of devices already, to avoid the expensive for loop.
                if isTrackingForEnoughTime(baseDevice: device, detections: relevantDetectionEvents),
                   
                    /// Only relevant if location access is denied
                     hasEnoughDetectionEvents(baseDevice: device, detections: relevantDetectionEvents),
                   
                    /// Check if minimum locations are reached
                   (!locationManager.hasAlwaysPermission() || hasMinDetectionDistance(baseDevice: device, detections: relevantDetectionEvents)) {

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
        
        // This is only relevant if location access was turned off
        return detections.count >= baseDevice.getType.constants.minDistinctLocations
    }
    
    
    /// Gets a list of detection events and checks if the user is being tracked for the minimum amount of time before a notification is sent.
    func isTrackingForEnoughTime(baseDevice: BaseDevice, detections: [DetectionEvent]) -> Bool {
        
        if let first = detections.first, let last = detections.last, let firstDate = first.time, let lastDate = last.time,
           firstDate.distance(to: lastDate) >= (baseDevice.getType.constants.minTrackingTime - TrackingDetection.trackingTimeBuffer) {
            
            return true
        }
        
        return false
    }
    
    
    /// Checks if the event is a tracking event
    func isTrackerInTrackingMode(for detectionEvent: DetectionEvent?) -> Bool {
        if let detectionEvent = detectionEvent {
            
            // In travel mode, we assume that the tracker is not malicious and the owner is nearby
            if detectionEvent.isTraveling {
                return false
            }
            
            // We can successfully read out the connection status from the DB
            if let connectionStatus = ConnectionStatus(rawValue: detectionEvent.connectionStatus ?? "") {
                return connectionStatus.isInTrackingMode()
            }
            
            // Some error occured (this might happen on version upgrade), we need to assume that event is tracking event
            return true
        }
        
        // No detection found
        return false
    }
    
    
    /// Checks if any detections meet the minimal distance requirement
    private func hasMinDetectionDistance(baseDevice: BaseDevice, detections: [DetectionEvent]) -> Bool {
        
        // Removes duplicate locations
        let withoutDuplicates = Set(detections.compactMap({$0.location}))
        
        // Since we cluster locations, just check how many distinct ones were collected
        return withoutDuplicates.count >= baseDevice.getType.constants.minDistinctLocations
    }
    
    
    /// Sends the user a notification if he/she has never received a notification for the tracker, or if the time to the last one is has surpassed a threshold
    func tryToRequestTrackerNotification(forTracker: BaseDevice, context: NSManagedObjectContext) {
        
        if let notifications = forTracker.notifications?.array as? [TrackerNotification], let firstSeen = forTracker.firstSeen {
            
            if(notifications.last?.time?.timeIntervalSinceNow ?? -.infinity < -TrackingDetection.secondsUntilAnotherNotification) {
                
                // create new notification ID
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
    
    
    /// Adds a detection event for the given device and stores it in the database. Important: the BaseDevice needs to be saved already!
    func addDetectionEvent(toDevice: BaseDevice, bluetoothData: BluetoothTempData, context: NSManagedObjectContext) {
        
        if BluetoothManager.sharedInstance.scanning && Settings.sharedInstance.lowPowerScan && Settings.sharedInstance.isBackground && LocationManager.sharedInstance.lastSignificantLocationUpdate.isOlderThan(seconds: minutesToSeconds(minutes: 10)) {
            log("Long time on this location. Save power: Disabling scan.")
            BluetoothManager.sharedInstance.stopScan()
        }
        
        if let lastDetectionEvent = toDevice.detectionEvents?.array.last as? DetectionEvent {
            if let previousSeen = lastDetectionEvent.time {
                
                let cooldown = Settings.sharedInstance.isBackground ? 7 : 3
                
                // do not record too many detection events
                if(!previousSeen.isOlderThan(seconds: minutesToSeconds(minutes: cooldown))) {
                    return
                }
            }
        }
        
        let deviceID = toDevice.objectID
        
        // store important data already, since location may be delayed
        let connectionStatus = toDevice.getType.constants.connectionStatus(advertisementData: bluetoothData.advertisementData_background).rawValue
        let time = toDevice.lastSeen
        let rssi = (bluetoothData.rssi_background) as NSNumber
        
        self.locationManager.getNewLocation() { [self] location, altitude, context in // location may be nil
            
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
                
                // If the user is currently higher than 3000m, we enable the traveling mode
                // In traveling mode, the detection mode is not considered for the tracking detection
                // As of now, we only support airplanes
                detectionEvent.isTraveling = altitude >= 3000
                
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

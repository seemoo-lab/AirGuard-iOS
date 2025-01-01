//
//  FetchDevices.swift
//  AirGuard
//
//  Created by Leon Böttger on 09.06.22.
//

import Foundation
import CoreData


/// Returns device with given identifier stored in database, nil if no such device exists
func fetchDeviceWithUniqueID(uuid: String, context: NSManagedObjectContext) -> BaseDevice? {
    
    return fetchDevices(withPredicate: NSPredicate(
        format: "uniqueId LIKE %@", uuid
    ), withLimit: 1, context: context).first
}


/// Returns device with given bluetooth identifier stored in database, nil if no such device exists
func fetchDeviceWithBluetoothID(uuid: String, context: NSManagedObjectContext) -> BaseDevice? {
    
    return fetchDevices(withPredicate: NSPredicate(
        format: "currentBluetoothId LIKE %@", uuid
    ), withLimit: 1, context: context).first
}


/// Retuns all SmartTags first seen in the last specified amount of seconds.
func fetchSmartTags(lastSeconds: Double, context: NSManagedObjectContext) -> [BaseDevice] {
    
    return fetchDevices(withPredicate: NSPredicate(
        format: "firstSeen >= %@ && deviceType == %@",
        Date().addingTimeInterval(-lastSeconds) as CVarArg,
        DeviceType.SmartTag.rawValue
    ), context: context)
}


/// Retuns all devices last seen in the specified number of minutes.
func fetchSeenDevices(lastMinutes: Int, context: NSManagedObjectContext) -> [BaseDevice] {
    
    return fetchDevices(withPredicate: NSPredicate(
        format: "lastSeen >= %@",
        Date().addingTimeInterval(-minutesToSeconds(minutes: lastMinutes)) as CVarArg
    ), context: context)
}


/// Removes all devices not seen for the last 15 days.
func cleanDatabase(context: NSManagedObjectContext) {
    
    if let threshold = Calendar.current.date(byAdding: .day, value: -15, to: Date()) {
        
        let oldDevices = fetchDevices(withPredicate: NSPredicate(format: "lastSeen < %@", threshold as CVarArg), context: context)
        
        delete(entries: oldDevices, context: context)
    }
}


/// Removes redundant detection events, that do not add any value for the tracking detection. For example, for three detections at the same location, the detection inbetween will be deleted.
func mergeTrackingEvents(context: NSManagedObjectContext) {
    for device in fetchDevices(context: context) {
        
        var firstDetectionAtLocation: DetectionEvent? = nil
        var previousDetectionAtLocation: DetectionEvent? = nil
        var toDelete: [DetectionEvent] = []
        
        for currentDetection in device.detectionEvents?.array as? [DetectionEvent] ?? [] {
            
            if firstDetectionAtLocation == nil {
                firstDetectionAtLocation = currentDetection
            }
            else {
                
                if let firstDetectionAtLocation = firstDetectionAtLocation, currentDetection.location == firstDetectionAtLocation.location && currentDetection.isTraveling == firstDetectionAtLocation.isTraveling && currentDetection.connectionStatus == firstDetectionAtLocation.connectionStatus {
                    
                    if let prev = previousDetectionAtLocation {
                        
                        // Safety checks
                        if (firstDetectionAtLocation == currentDetection || previousDetectionAtLocation == currentDetection || previousDetectionAtLocation == firstDetectionAtLocation
                            
                            || prev.isTraveling != currentDetection.isTraveling || prev.connectionStatus != currentDetection.connectionStatus || prev.location != currentDetection.location
                            
                            || prev.isTraveling != firstDetectionAtLocation.isTraveling || prev.connectionStatus != firstDetectionAtLocation.connectionStatus || prev.location != firstDetectionAtLocation.location) {
                            log("----------------------------------------")
                            log("ERROR MERGING TRACKING EVENTS. QUITTING.")
                            log("----------------------------------------")
                            return
                        }
                        
                        toDelete.append(prev)
                    }
                    
                    previousDetectionAtLocation = currentDetection
                }
                else {
                    firstDetectionAtLocation = currentDetection
                    previousDetectionAtLocation = nil
                }
            }
        }
        delete(entries: toDelete, context: context)
    }
}


/// Removes all devices not seen for the last 30 days.
func removeAllDevicesWithNoNotificationOlderThan30Days(context: NSManagedObjectContext) {
    
    if let threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date()) {
        
        // avoid removing ignored devices, to not reset the ignore flag on those
        let oldDevices = fetchDevices(withPredicate: NSPredicate(format: "ignore == FALSE && lastSeen < %@", threshold as CVarArg), context: context)
        let neverSentNotification = oldDevices.filter({ ($0.notifications?.count ?? 0) == 0 })
        
        delete(entries: neverSentNotification, context: context)
    }
}

/// Removes all detections that are older than 30 days and the associated device did not produce a tracking notification.
func removeAllDetectionsWithNoNotificationOlderThan30Days(context: NSManagedObjectContext) {
    
    if let threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date()) {
        
        // avoid removing ignored devices, to not reset the ignore flag on those
        let oldDetections = fetchDetections(withPredicate: NSPredicate(format: "time < %@", threshold as CVarArg), context: context)
        print("Found \(oldDetections.count) detections older than 30 days")
        
        let neverSentNotification = oldDetections.filter({ $0.baseDevice?.notifications?.count ?? 0 == 0 })
        print("Found \(neverSentNotification.count) detections with no tracking notification")
        
        delete(entries: neverSentNotification, context: context)
    }
}


/// Fetches all devices meeting the predicate. Limit of array can be specified in `withLimit`.
func fetchDevices(withPredicate: NSPredicate? = nil, withLimit: Int? = nil, context: NSManagedObjectContext) -> [BaseDevice] {
    
    // create fetch request
    let fetchRequest: NSFetchRequest<BaseDevice>
    fetchRequest = BaseDevice.fetchRequest()
    
    // set limit
    if let withLimit = withLimit {
        fetchRequest.fetchLimit = withLimit
    }
    
    // set predicate
    fetchRequest.predicate = withPredicate
    
    // try to fetch
    do {
        let objects = try context.fetch(fetchRequest)
        
        return objects
    }
    
    // error occured
    catch {
        log(error.localizedDescription)
    }
    
    // default: nothing to return
    return []
}


/// Fetches all detection events meeting the predicate.
func fetchDetections(withPredicate: NSPredicate? = nil, context: NSManagedObjectContext) -> [DetectionEvent] {
    
    // create fetch request
    let fetchRequest: NSFetchRequest<DetectionEvent>
    fetchRequest = DetectionEvent.fetchRequest()
    
    // set predicate
    fetchRequest.predicate = withPredicate
    
    // try to fetch
    do {
        let objects = try context.fetch(fetchRequest)
        
        return objects
    }
    
    // error occured
    catch {
        log(error.localizedDescription)
    }
    
    // default: nothing to return
    return []
}


/// Fetches and returns the device on the CoreData background queue
func modifyDeviceOnBackgroundThread(objectID: NSManagedObjectID, callback: @escaping (NSManagedObjectContext, BaseDevice) -> ()) {
    PersistenceController.sharedInstance.modifyDatabaseBackground { context in
        
        if let device = context.object(with: objectID) as? BaseDevice {
            callback(context, device)
        }
    }
}


/// Deletes the specified entried from the database.
func delete<T: NSManagedObject>(entries: [T], context: NSManagedObjectContext) {
    for entry in entries {
        context.delete(entry)
    }
}


/// Triggers a fake tracking notification.
func addFakeNotification(context: NSManagedObjectContext) {
    
    Settings.sharedInstance.securityLevel = .High
    
    let device = BaseDevice(context: context)
    device.setType(type: .Tile)
    device.firstSeen = Date().addingTimeInterval(-3600)
    device.lastSeen = Date()
    device.uniqueId = UUID().uuidString
    device.currentBluetoothId = device.uniqueId
    
    let latitudes = [51.188777831702524, 51.18463543547539, 51.189239879202825]
    let longtitudes = [8.920169427825071, 8.939138009645319, 8.962054803066161]
    
    
    let detectionEvent = DetectionEvent(context: context)
    
    detectionEvent.connectionStatus = ConnectionStatus.Offline.rawValue
    detectionEvent.time = Date.distantPast
    detectionEvent.baseDevice = device
    

    for index in 0..<latitudes.count{
        let detectionEvent = DetectionEvent(context: context)
        
        detectionEvent.connectionStatus = ConnectionStatus.Offline.rawValue
        detectionEvent.time = device.lastSeen?.addingTimeInterval(TimeInterval(-60 * 15 * (latitudes.count - index)))
        detectionEvent.baseDevice = device
        
        let location = Location(context: context)
        
        location.latitude = latitudes[index]
        location.longitude = longtitudes[index]
        location.accuracy = 1
        
        detectionEvent.location = location
    }
    
    TrackingDetection.sharedInstance.checkIfTracked(device: device, context: context)
}


/// Fills the database with 1000 dummy devices and corresponding detectionEvents.
func addDummyData() {
    
    PersistenceController.sharedInstance.modifyDatabaseBackground { privateMOC in
        
        let max = 1000
        
        for i in 0..<max {
            
            print("Progress: \(100*Double(i)/Double(max))%")
            
            let device = BaseDevice(context: privateMOC)
            device.setType(type: .AirTag)
            device.firstSeen = Date.distantPast
            device.lastSeen = Date.distantPast
            device.uniqueId = UUID().uuidString
            device.currentBluetoothId = device.uniqueId
            
            for _ in 0..<3 {
                let detectionEvent = DetectionEvent(context: privateMOC)
                
                detectionEvent.time = Date.distantPast
                detectionEvent.baseDevice = device
                
                let location = Location(context: privateMOC)
                
                location.latitude = 52
                location.longitude = 8
                location.accuracy = 1
                
                detectionEvent.location = location
            }
        }
    }
}


/// Fetches all notifications from the database with the given predicate.
func fetchNotifications(withPredicate: NSPredicate? = nil, withLimit: Int? = nil, context: NSManagedObjectContext) -> [TrackerNotification] {
    let fetchRequest: NSFetchRequest<TrackerNotification>
    fetchRequest = TrackerNotification.fetchRequest()
    
    if let withLimit = withLimit {
        fetchRequest.fetchLimit = withLimit
    }
    
    fetchRequest.predicate = withPredicate

    do {
        let objects = try context.fetch(fetchRequest)
        
        return objects
    }
    catch {
        log(error.localizedDescription)
    }
    return []
}

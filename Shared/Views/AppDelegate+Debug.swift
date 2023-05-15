//
//  AppDelegate+Debug.swift
//  AirGuard (iOS)
//
//  Created by Alex - SEEMOO on 30.01.23.
//

import Foundation
import CoreLocation

extension AppDelegate {
    func evaluateDebugLaunchArguments() {
        let launchArguments = ProcessInfo.processInfo.arguments
        
        if launchArguments.contains("--showOnboarding") {
            Settings.sharedInstance.appLaunchedBefore = false
            Settings.sharedInstance.tutorialCompleted = false 
        }
        
        if let index = launchArguments.firstIndex(of: "--addDummyData") {
            let level = launchArguments[index+1]
            addDummyData(level: level)
        }
        
        if launchArguments.contains("--removeDummyData") {
            self.removeDummyData()
        }
        
        if launchArguments.contains("--sendNotification") {
            self.sendTrackingNotification()
        }
    }
    
    func addDummyData(level: String) {
        switch level {
        case "green":
            // Add tracker that did not cause a notification
            createDummyTracker(lastSeen: nil, notifications: 0)
        case "orange":
            // Add 1 tracker that caused a notification
            createDummyTracker(lastSeen: nil, notifications: 1)
        case "red":
            // Add several trackers that caused a notification
            createDummyTracker(lastSeen: nil, notifications: 2)
        default:
            break
        }
    }
    
    func createDummyTracker(lastSeen: Date?, notifications: Int = 1) {
        let context = PersistenceController.sharedInstance.container.viewContext
        let device = BaseDevice(context: context)
        device.deviceType = "DUMMY"
        let lastSeen = lastSeen ?? Date() - Double(arc4random() % 10) * 24 * 60 * 60
        device.lastSeen = lastSeen
        device.ignore = false
        device.firstSeen = lastSeen - 12 * 60 * 60
        device.uniqueId = UUID().uuidString
        device.name = "Samsung SmartTag"
        
        for i in 0..<notifications {
            let notification = TrackerNotification(context: context)
            notification.baseDevice = device
            notification.time = lastSeen - Double(i) * 8 * 60 * 60
            notification.tapped = true
            notification.identifier = UUID()
        }
        
        if notifications > 0 {
            let seenLocations = [
                CLLocation(latitude: 51.4970743, longitude: -0.1339056),
                CLLocation(latitude: 51.5007292, longitude: -0.1246254),
                CLLocation(latitude: 51.4993695, longitude: -0.1272993),
                CLLocation(latitude: 51.501364, longitude: -0.14189),
                CLLocation(latitude: 51.5031393, longitude: -0.1627144),
                CLLocation(latitude: 51.5142112, longitude: -0.1485351)
                ]
            // Create locations for each entry in London
            
            for (idx, location) in seenLocations.enumerated() {
                let dbLoc = Location(context: context)
                dbLoc.accuracy = 40.0
                dbLoc.latitude = location.coordinate.latitude
                dbLoc.longitude = location.coordinate.longitude
                
                let detectionEvent = DetectionEvent(context: context)
                detectionEvent.time = lastSeen - 15 * 60 * Double(idx)
                detectionEvent.baseDevice = device
                detectionEvent.rssi = -70
                dbLoc.addToDetections(detectionEvent)
            }
        }
        
        do {
            try context.save()
        }catch {
            log("Dummy data could not be added \(error.localizedDescription)")
        }
    }
    
    func removeDummyData() {
        let dummyTrackersPredicate = NSPredicate(format: "deviceType = %@", "DUMMY")
        let dummyDevices = fetchDevices(withPredicate: dummyTrackersPredicate, withLimit: nil, context: PersistenceController.sharedInstance.container.viewContext)
        for dummyDevice in dummyDevices {
            PersistenceController.sharedInstance.container.viewContext.delete(dummyDevice)
        }
        
        do {
            try PersistenceController.sharedInstance.container.viewContext.save()
        }catch {
            log("Dummy data could not be deleted \(error.localizedDescription)")
        }
    }
    
    func sendTrackingNotification() {
        // Get the last dummy device
        let dummyTrackersPredicate = NSPredicate(format: "deviceType = %@", "DUMMY")
        let dummyDevices = fetchDevices(withPredicate: dummyTrackersPredicate, withLimit: nil, context: PersistenceController.sharedInstance.container.viewContext)
        guard let dummyDevice = dummyDevices.last else {return}
        
        
        TrackingDetection.sharedInstance.tryToRequestTrackerNotification(forTracker: dummyDevice, context: PersistenceController.sharedInstance.container.viewContext)
        
    }
}

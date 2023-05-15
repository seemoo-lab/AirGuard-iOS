//
//  BaseDevice+CoreDataProperties.swift
//  AirGuard
//
//  Created by Leon Böttger on 14.05.22.
//
//

import Foundation
import CoreData
import CoreBluetooth


/// Class extensions of BaseDevice
extension BaseDevice  {

    /// CoreData fetch request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseDevice> {
        return NSFetchRequest<BaseDevice>(entityName: "BaseDevice")
    }
    

    /// The device type of the tracker, raw data of `DeviceType`
    @NSManaged public var deviceType: String?
    
    /// The date the device was seen for the first time
    @NSManaged public var firstSeen: Date?
    
    /// True if the device should be ignored for background scanning.
    @NSManaged public var ignore: Bool

    /// The date the device was seen for the last time
    @NSManaged public var lastSeen: Date?
    
    /// The custom name of the device. `nil` if device type name is used.
    @NSManaged public var name: String?
    
    /// The identifier to identify the device. This ID does not change and is set to the Bluetooth UUID on first discovery of the device.
    @NSManaged public var uniqueId: String?
    
    /// The Bluetooth UUID of the device. This can be different to the `uniqueId` since tracker might change their MAC address.
    @NSManaged public var currentBluetoothId: String?
    
    /// Additional data used for identification, for example the service data.
    @NSManaged public var additionalData: String?
    
    /// The date when the observing of a tracker should start. This is different to the date the user enabled observation of the tracker.
    @NSManaged public var observingStartDate: Date?
    
    /// The date the device changed its MAC address. This value always changed together with `currentBluetoothId`
    @NSManaged public var lastMacRenewal: Date?
    
    /// The detections of the device.
    @NSManaged public var detectionEvents: NSOrderedSet?
    
    /// All sent tracking notification for this device.
    @NSManaged public var notifications: NSOrderedSet?
   
}


// MARK: Generated accessors for detectionEvents
extension BaseDevice {

    @objc(insertObject:inDetectionEventsAtIndex:)
    @NSManaged public func insertIntoDetectionEvents(_ value: DetectionEvent, at idx: Int)

    @objc(removeObjectFromDetectionEventsAtIndex:)
    @NSManaged public func removeFromDetectionEvents(at idx: Int)

    @objc(insertDetectionEvents:atIndexes:)
    @NSManaged public func insertIntoDetectionEvents(_ values: [DetectionEvent], at indexes: NSIndexSet)

    @objc(removeDetectionEventsAtIndexes:)
    @NSManaged public func removeFromDetectionEvents(at indexes: NSIndexSet)

    @objc(replaceObjectInDetectionEventsAtIndex:withObject:)
    @NSManaged public func replaceDetectionEvents(at idx: Int, with value: DetectionEvent)

    @objc(replaceDetectionEventsAtIndexes:withDetectionEvents:)
    @NSManaged public func replaceDetectionEvents(at indexes: NSIndexSet, with values: [DetectionEvent])

    @objc(addDetectionEventsObject:)
    @NSManaged public func addToDetectionEvents(_ value: DetectionEvent)

    @objc(removeDetectionEventsObject:)
    @NSManaged public func removeFromDetectionEvents(_ value: DetectionEvent)

    @objc(addDetectionEvents:)
    @NSManaged public func addToDetectionEvents(_ values: NSOrderedSet)

    @objc(removeDetectionEvents:)
    @NSManaged public func removeFromDetectionEvents(_ values: NSOrderedSet)

}

// MARK: Generated accessors for notifications
extension BaseDevice {

    @objc(insertObject:inNotificationsAtIndex:)
    @NSManaged public func insertIntoNotifications(_ value: Notification, at idx: Int)

    @objc(removeObjectFromNotificationsAtIndex:)
    @NSManaged public func removeFromNotifications(at idx: Int)

    @objc(insertNotifications:atIndexes:)
    @NSManaged public func insertIntoNotifications(_ values: [Notification], at indexes: NSIndexSet)

    @objc(removeNotificationsAtIndexes:)
    @NSManaged public func removeFromNotifications(at indexes: NSIndexSet)

    @objc(replaceObjectInNotificationsAtIndex:withObject:)
    @NSManaged public func replaceNotifications(at idx: Int, with value: Notification)

    @objc(replaceNotificationsAtIndexes:withNotifications:)
    @NSManaged public func replaceNotifications(at indexes: NSIndexSet, with values: [Notification])

    @objc(addNotificationsObject:)
    @NSManaged public func addToNotifications(_ value: Notification)

    @objc(removeNotificationsObject:)
    @NSManaged public func removeFromNotifications(_ value: Notification)

    @objc(addNotifications:)
    @NSManaged public func addToNotifications(_ values: NSOrderedSet)

    @objc(removeNotifications:)
    @NSManaged public func removeFromNotifications(_ values: NSOrderedSet)

}

extension BaseDevice : Identifiable {

}

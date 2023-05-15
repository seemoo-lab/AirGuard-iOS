//
//  PersistenceController.swift
//  CoreDataSync
//

import CoreData
import UIKit

/// Singleton for the CoreData view context
struct PersistenceController {
    
    /// The shared instance
    static let sharedInstance = PersistenceController()
    
    /// Primary container for CoreData model
    let container: NSPersistentContainer = {
        
        /// Has to be name of the xcdatamodeld File
        let databaseName = "DataModel"
        
        /// File path to database on disk
        let storeURL = AppGroup.containerURL.appendingPathComponent(databaseName + ".sqlite")
        
        /// Description for the custom file path
        let description = NSPersistentStoreDescription(url: storeURL)
        
        /// The container of the database
        let container = NSPersistentContainer(name: databaseName)
        
        /// Set merge policy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        /// Should not do anything, but might avoid crashes
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        /// Apply custom path
        container.persistentStoreDescriptions = [description]
        
        /// Loads the persistence store after initializing it
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
            /// Something went wrong
            if let error = error as NSError? {
                log(error.localizedDescription)
            }
        })
        
        /// Return the database
        return container
    }()
    
    
    /// Writes any changes to CoreData model to disk.
    /// If possible, do not use this method for modifying the database.
    /// All write operations should be performed in the background, read operations may be executed on the main thread.
    func modifyDatabase(task: @escaping (NSManagedObjectContext) -> ()) {
        
        /// perform all operations on the same thread to avoid race conditions
        DispatchQueue.main.async {
            
            let context = container.viewContext
            
            // perform action synchronously
            context.performAndWait {
                
                task(context)
                
                /// only perform if any changes made to model
                if context.hasChanges {
                    
                    do {
                        /// write to disk
                        try context.save()
                    }
                    catch {
                        /// some error occured
                        log(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    
    /// Manually syncs the given background context with the main context. The private moc has to be created with `newBackgroundContext`
    func sync(privateMOC: NSManagedObjectContext) {
        
        if privateMOC.hasChanges {

            do {
                try privateMOC.save()
                
            } catch {
                
                log("Could not sync data! \(error), \(error.localizedDescription)")
            }
        }
    }
    
    
    /// background thread for database work in background.
    let backgroundQueue = DispatchQueue(label: "databaseQueue", qos: .utility)
    
    
    /// Writes any changes to CoreData model to disk.
    /// Peforms all work on a background queue and merges changes into main context afterwards (serialized).
    func modifyDatabaseBackground(task: @escaping (NSManagedObjectContext) -> ()) {
        
        /// perform all operations in background - serialized (!!!)
        backgroundQueue.async {
            
            /// create new background context
            let privateMOC = container.newBackgroundContext()
            
            /// serialize operations
            privateMOC.performAndWait {
                
                /// Perform task
                task(privateMOC)
                
                if privateMOC.hasChanges {
                    
                    /// merge in main context
                    do {
                        try privateMOC.save()
                        
                    } catch {
                        log("Could not sync data! \(error), \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

/// Contains information about the app group used to share data between main app and widget
struct AppGroup {
    
    /// Identifier of the app group
    static let appGroupName = "group." + Bundle.main.bundleIdentifier!
    
    /// Container URL of the app group
    static var containerURL: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.appGroupName)!
    }
}

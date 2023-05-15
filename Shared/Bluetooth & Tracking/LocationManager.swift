//
//  LocationManager.swift
//  AirGuard
//
//  Created by Leon Böttger on 18.04.22.
//

import Foundation
import CoreLocation
import CoreBluetooth
import CoreData


/// Struct for requests to new locations
struct LocationRequest: Identifiable, Equatable {
    
    static func == (lhs: LocationRequest, rhs: LocationRequest) -> Bool {
        lhs.id == rhs.id
    }
    
    /// The ID of the request
    let id = UUID()
    
    /// The callback after the location was retrieved
    let callback: (Location?, NSManagedObjectContext) -> Void
    
    /// The start date of the request
    let date = Date()
}


/// Handles management of GPS locations.
open class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    /// The instance of the CL location manager
    var locationManager: CLLocationManager?
    
    /// last accurate location stored in database
    var lastLocation: CLLocation?
    
    /// last update of location
    var lastUpdate = Date.distantPast
    
    /// last significant location update
    var lastSignificantLocationUpdate = Date()
    
    /// true if app has location access
    @Published var permissionSet = false
    
    /// The shared instance
    static var sharedInstance = LocationManager()
    
    /// specifies in seconds how long to use old cached location until a new request is made
    let secondsUntilNewLocation: Double = 50
    
    /// specifies the (exclusive) limit of the accepted accuracy for received locations
    let accuracyLimit: Double = (TrackingDetection.minLocationDist/2)
    
    /// saves callbacks of all interested clients
    var callbacks = [LocationRequest]()
    
    /// Date when the last location was requested.
    var locationUpdateStart = Date.distantPast
    
    /// The background queue to perform location tasks.
    private let locationManagerQueue = DispatchQueue(label: "locationManagerQueue")
    
    
    /// sets up the location manager
    override private init() {
        super.init()
        
        // Create a location manager object
        locationManager = CLLocationManager()
        
        // Set delegate
        locationManager?.delegate = self
        
        // Set the accuracy
        locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        if Settings.sharedInstance.backgroundScanning {
            enableBackgroundLocationUpdate()
        }
    }
    
    /// Enables automatic update of location in the background
    func enableBackgroundLocationUpdate() {
        
        log("Enabling Background Location...")
        
        // Enable background location updates
        locationManager?.allowsBackgroundLocationUpdates = true
        
        // Enable significant location update
        locationManager?.startMonitoringSignificantLocationChanges()
    }
    
    
    /// Disables automatic update of location in the background
    func disableBackgroundLocationUpdate() {

        log("Disabling Background Location...")
        
        // Enable background location updates
        locationManager?.allowsBackgroundLocationUpdates = false
        
        // Enable significant location update
        locationManager?.stopMonitoringSignificantLocationChanges()
    }
    
    
    /// requests always usage of location to user
    func requestAlwaysUsage() {
        locationManager?.requestAlwaysAuthorization()
    }
    
    /// requests when in use usage of location to user
    func requestWhenInUse() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    
    /// gets called if autorization status changes
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedAlways && manager.accuracyAuthorization == .fullAccuracy {
            log("Accepted Always")
            permissionSet = true
            NotificationManager.sharedInstance.removeLocationStoppedNotification()
        }
        else {
            if Settings.sharedInstance.tutorialCompleted {
                NotificationManager.sharedInstance.sendLocationStoppedNotification()
            }
            
            if status == .authorizedWhenInUse && manager.accuracyAuthorization == .fullAccuracy {
                log("Accepted when in use")
                permissionSet = true
            }
            else {
                log("Location Disabled!")
                permissionSet = false
            }
        }
    }
    
    
    /// returns if authorization is set to "Always"
    public func hasAlwaysPermission() -> Bool {
        return locationManager?.authorizationStatus == .authorizedAlways && locationManager?.accuracyAuthorization == .fullAccuracy
    }
    
    
    /// gets called if system received new location
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if Settings.sharedInstance.isBackground {
            
            // system woke up, use chance  restart scan if necessary
            if(!BluetoothManager.sharedInstance.scanning) {
                startBluetooth()
            }
        }
        
        locationManagerQueue.async { [self] in
            
            /// no client is interested in a new location
            if callbacks.isEmpty {
                log("Significant Location Update")
                lastSignificantLocationUpdate = Date()
                
                self.locationManager?.stopUpdatingLocation()
                
                return
            }
            
            log("Received Location With Accuracy \(locations.last?.horizontalAccuracy ?? -1), age: \(Date().timeIntervalSince(locations.last?.timestamp ?? Date.distantPast))")
            
            if let location = locations.last, // last entry is the most recent one
               location.horizontalAccuracy < accuracyLimit, // only accept locations with a specified accuracy
               Date().timeIntervalSince(location.timestamp) < secondsUntilNewLocation, // only accept recent locations
               lastUpdate.isOlderThan(seconds: secondsUntilNewLocation) { // Sometimes multiple locations are delivered, just take the first
                
                // We are now done searching
                self.locationManager?.stopUpdatingLocation()
                
                log("Provided new location in \(Int(self.locationUpdateStart.distance(to: Date())))s")
                lastLocation = location
                lastUpdate = Date()
                
                // Store location in database or retrieve old one
                getCoreDataLocation(forLocation: location) { [self] coreDataLocation, context in
                    finishCallback(withLocation: coreDataLocation, context: context)
                }
            }
        }
    }

    
    /// provides new location to all interested clients
    func finishCallback(withLocation: Location, context: NSManagedObjectContext) {
            
            for callback in callbacks {
                
                // discard entries which are older than X minutes
                if(!callback.date.isOlderThan(seconds: minutesToSeconds(minutes: 1))) {
                    callback.callback(withLocation, context)
                }
                else {
                    callback.callback(nil, context)
                }
            }
            
            callbacks.removeAll()
    }
    
    
    /// requests new location if necessary and calls client back
    func getNewLocation(callback: @escaping (Location?, NSManagedObjectContext) -> Void) {
        
        if(permissionSet &&
           (!Settings.sharedInstance.isBackground || locationManager?.authorizationStatus == .authorizedAlways)) {
            
            locationManagerQueue.async { [self] in
                
                if(lastUpdate.isOlderThan(seconds: secondsUntilNewLocation)) {
                    
                    log("Waiting for new location update. Last refresh: \(lastUpdate.timeIntervalSinceNow)s ago")

                    let request = LocationRequest(callback: callback)
                    callbacks.append(request)
                    
                    self.locationUpdateStart = Date()
                    self.locationManager?.startUpdatingLocation()
                    
                    
                    // Check if request is handled after one minute
                    locationManagerQueue.asyncAfter(deadline: .now() + minutesToSeconds(minutes: 1), execute: {
                        
                        // still no location received and no new requests were made
                        if self.callbacks.last == request {
                            
                            log("Stopping GPS. No Location found.")
                            
                            // do not keep GPS on all the time if no location was found
                            self.locationManager?.stopUpdatingLocation()
                        }
                    })
                }
                else {
                    if let lastLocation = lastLocation {
                        log("Provided location in 0s")
                        getCoreDataLocation(forLocation: lastLocation) { coreDataLocation, context in
                            callback(coreDataLocation, context)
                        }
                    }
                    else {
                        log("Can't provide location!")
                        PersistenceController.sharedInstance.modifyDatabaseBackground { context in
                            callback(nil, context)
                        }
                    }
                }
            }
        }
        else {
            log("Can't provide location!")
            PersistenceController.sharedInstance.modifyDatabaseBackground { context in
                callback(nil, context)
            }
        }
    }
    
    
    /// Returns a location around the provided location already stored in CoreData or creates a new if no location was present in CoreData
    func getCoreDataLocation(forLocation: CLLocation, callback: @escaping (Location, NSManagedObjectContext) -> () ) {
        
        PersistenceController.sharedInstance.modifyDatabaseBackground { [self] context in
            
            // Search for all locations which are less than accuracyLimit from the location. If there is one, we take it to reduce the locations in the database.
            let databaseLocation = fetchLocation(aroundLocation: forLocation, radius: accuracyLimit, context: context)
            
            // take old one
            if let existingLocation = databaseLocation {
                log("Took old location")
                callback(existingLocation, context)
            }
            else {
                // create new location in database
                log("Received new location")
                let newLocation = Location(context: context)
                newLocation.accuracy = forLocation.horizontalAccuracy
                newLocation.latitude = forLocation.coordinate.latitude
                newLocation.longitude = forLocation.coordinate.longitude
                
                callback(newLocation, context)
            }
        }
    }



    /// idea from https://stackoverflow.com/questions/23015484/calculating-max-and-min-latitude-and-longitude-with-distance-from-location-obj
    /// Fetches locations around the location and radius provided. Radius is EXCLUSIVE.
    func fetchLocation(aroundLocation: CLLocation, radius: Double, context: NSManagedObjectContext) -> Location? {
        
        let searchDistance = radius / 1000 // convert value to KM

        let minLat = aroundLocation.coordinate.latitude - (searchDistance / 69)
        let maxLat = aroundLocation.coordinate.latitude + (searchDistance / 69)

        let minLon = aroundLocation.coordinate.longitude - searchDistance / fabs(cos(deg2rad(aroundLocation.coordinate.latitude)) * 69)
        let maxLon = aroundLocation.coordinate.longitude + searchDistance / fabs(cos(deg2rad(aroundLocation.coordinate.latitude)) * 69)
        
        let predicate = NSPredicate(format: "latitude <= \(maxLat) AND latitude >= \(minLat) AND longitude <= \(maxLon) AND longitude >= \(minLon)")
        
        let fetchRequest: NSFetchRequest<Location>
        fetchRequest = Location.fetchRequest()
        
        fetchRequest.predicate = predicate
        
        do {
            let objects = try context.fetch(fetchRequest)
            
            var closestLocation: Location? = nil
            var closestLocationDistance: Double = Double.infinity
            
            // We fetched older locations which are located in a rectangle around the new location (for efficiency reasons). We now need to get the ones which are in the circle around the new location
            for location in objects {
                
                let databaseLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                let distance = databaseLocation.distance(from: aroundLocation)
                
                if(distance < radius && distance < closestLocationDistance) {
                    
                    closestLocation = location
                    closestLocationDistance = distance
                }
            }
            
            if let closestLocation = closestLocation {
                
                // update location accuracy to reflect the worst case
                let newLocationAccuracy = aroundLocation.horizontalAccuracy
                let newExistingLocationAccuracy = newLocationAccuracy + closestLocationDistance
                
                if(newExistingLocationAccuracy > closestLocation.accuracy) {
                    closestLocation.accuracy = newExistingLocationAccuracy
                }
                
                return closestLocation
            }
            
        }
        catch {
            log(error.localizedDescription)
        }
        
        // nothing found
        return nil
    }

    
    /// Converts degrees to radians
    func deg2rad(_ degrees: Double) -> Double{
        return degrees * Double.pi / 180
    }
}

//
//  SendStatisticsController.swift
//  AirGuard (iOS)
//
//  Created by Alex - SEEMOO on 24.01.23.
//

import Foundation
import BackgroundTasks

actor SendStatisticsController {
    
    var lastDataDonation: Date {
        didSet {
            UserDefaults.standard.set(date: lastDataDonation, forKey: "lastDataDonation")
        }
    }
    var donorToken: String? {
        didSet {
            UserDefaults.standard.set(donorToken, forKey: "dataDonatorToken")
        }
    }
    
    init(lastDataDonation: Date?=nil, donorToken: String?=nil) {
        // Variables can be passed for testing
        
        if let lastDataDonation {
            self.lastDataDonation = lastDataDonation
        } else {
            self.lastDataDonation = UserDefaults.standard.date(forKey: "lastDataDonation") ?? .distantPast
        }
        
        if let donorToken {
            self.donorToken = donorToken
        } else {
            self.donorToken = UserDefaults.standard.string(forKey: "dataDonatorToken")
        }
    }
    
    /// Get all devices that should be donated since the last data donation
    /// - Returns: Array of devices to donate to the server
    func donationData() async -> [API_Request.Device] {
        
        let backgroundContext = PersistenceController.sharedInstance.container.newBackgroundContext()
        
        let predicate = NSPredicate(format: "lastSeen >= %@", lastDataDonation as CVarArg)
        let devices = fetchDevices(withPredicate: predicate, context: backgroundContext)
        
        // Convert to API_Request types
        var deviceArrayToDonate = [API_Request.Device]()
        
        for device in devices {
            
            guard let id = device.uniqueId,
                  let firstDiscovery = device.firstSeen,
                  let lastDiscovery = device.lastSeen,
                  let deviceType = device.deviceType else {
                continue
            }
            
            //Get beacons for device
            let detectionEvents = device.detectionEvents
            let beacons = detectionEvents?.compactMap({ element -> API_Request.Beacon? in
                if let detectionEvent = element as? DetectionEvent,
                   let time = detectionEvent.time,
                   let rssi = detectionEvent.rssi?.intValue, let connectionState = detectionEvent.connectionStatus,
                   connectionState != ConnectionStatus.Connected.rawValue {
                    return API_Request.Beacon(receivedAt: time, rssi: rssi, serviceUUIDs: [], connectionState: connectionState)
                }
                return nil
            })
            
            //Get the notifications
            let notificationSet = device.notifications
            let notifications = notificationSet?.compactMap({ element -> API_Request.Notification? in
                
                guard let notification = element as? TrackerNotification,
                      let time = notification.time else {
                    return nil
                }
                
                var feedback: API_Request.Feedback? = nil
                
                if let location = notification.hideout, location != "" {
                    feedback = API_Request.Feedback(location: location)
                }
                
                return API_Request.Notification(falseAlarm: notification.falseAlarm, dismissed: false, clicked: notification.tapped, createdAt: time, feedback: feedback)
            })
            
            let apiDevice = API_Request.Device(uniqueId: id, ignore: device.ignore, connectable: false, firstDiscovery: firstDiscovery, lastSeen: lastDiscovery, deviceType: deviceType, beacons: beacons ?? [], notifications: notifications ?? [])
            
            deviceArrayToDonate.append(apiDevice)
        }
        
        return deviceArrayToDonate
    }
    
    func sendStats() async throws {
        guard Constants.StudyIsActive else {return}
        
        // Check if the user wants to participate in the study
        guard Settings.sharedInstance.participateInStudy || UserDefaults.standard.bool(forKey: UserDefaultKeys.participateInStudy.rawValue)  else {
            return
        }
        
        //Check if the last upload is minimum 24h ago
        guard lastDataDonation.isOlderThan(seconds: 24 * 60 * 60) else {
            return
        }
        
        //Check if the server is available
        guard await API.pingServer() else {
            // Stop here and try again later
            throw StatisticsError.serverDown
        }
        
        // Get all the necessary Devices, Beacons, Notifications and Feedback since the last donation
        
        let donationData = await self.donationData()
        
        guard !donationData.isEmpty else {
            log("No new devices found. Stopping donation here")
            return
        }
        
        // Check if we have a token, otherwise request one
        if self.donorToken == nil {
            do {
                let token = try await API.getToken()
                self.donorToken = token.token
            }catch {
                log("Was not able to get a donation token \(error.localizedDescription)")
                throw StatisticsError.didNotGetToken(info: error.localizedDescription)
            }
        }
        
        // Upload the data
        guard let donorToken = self.donorToken else {
            log("No donor token available.")
            assert(false, "Should not reach this state here")
            throw StatisticsError.didNotGetToken(info: "")
        }
        
        do {
            try await API.donateData(token: donorToken, devices: donationData)
            // Update the last donation date
            self.lastDataDonation = Date()
        }catch {
            log("Data donation failed \(error.localizedDescription)")
            throw StatisticsError.uploadFailed(info: error.localizedDescription)
        }
        
    }
    
    //MARK: Background tasks
    
    func handleBackgroundTaskDataDonation(task: BGAppRefreshTask) async {
        // Schedule next execution
        scheduleDataDonation()
        
        let donateDataTask = Task(priority: .high) {
            do {
                try await sendStats()
            } catch {
                log("Failed donating data \(error.localizedDescription)")
            }
        }
        
        task.expirationHandler = {
            donateDataTask.cancel()
        }
        
        // Upload completed or not necessary yet
        let _ = await donateDataTask.result
        
        task.setTaskCompleted(success: true)
    }
    
    func scheduleDataDonation() {
        let request = BGAppRefreshTaskRequest(identifier: "de.tu-darmstadt.seemoo.airguard.donateData")
        // Fetch no earlier than 24h from now
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            log("Failed submitting new background refresh task \(error.localizedDescription)")
        }
    }
}

enum StatisticsError: Error {
    case didNotGetToken(info: String)
    case serverDown
    case uploadFailed(info: String)
}

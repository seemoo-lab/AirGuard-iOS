//
//  Api.swift
//  AirGuard (iOS)
//
//  Created by Alex - SEEMOO on 24.01.23.
//

import Foundation
import UIKit


struct API {
    
    static let userAgent: String = {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let buildVersion = Bundle.main.infoDictionary?["CFBundleVersionString"] as? String {
            return "AirGuard/\(appVersion)(\(buildVersion)); iOS \(UIDevice.current.systemVersion)"
        }
        
        return "AirGuard; iOS \(UIDevice.current.systemVersion)"
    }()
    
    /// Returns true when the ping to the server has been successful
    /// - Returns: True when succesful
    static func pingServer() async -> Bool {
        do {
            var request = URLRequest(url: baseURL.appendingPathComponent("ping"), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
            
            request = addAuthentication(request: request)
            
            let (data, _) = try await URLSession.shared.asyncData(for: request)
            
            let pong = try JSONDecoder().decode(API_Response.Pong.self, from: data)
            
            return pong.response.lowercased() == "pong"
        }catch {
            log("Failed accessing the server \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get a new token. This also creates a new DataDonor. Should only be done once per App installation.
    static func getToken() async throws -> API_Response.Token {
        var request = URLRequest(url: baseURL.appendingPathComponent("get_token"), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        request = addAuthentication(request: request)
        
        let (data, _) = try await URLSession.shared.asyncData(for: request)
        
        let token = try JSONDecoder().decode(API_Response.Token.self, from: data)
        
        return token
    }
    
    static func donateData(token: String, devices: [API_Request.Device]) async throws  {
        
        #if DEBUG
        // Don't allow data donations to the production server in debug builds
        guard !baseURL.absoluteString.lowercased().contains("tpe.seemoo.tu-darmstadt.de") else {
            return
        }
        #endif
        
        var request = URLRequest(url: baseURL.appendingPathComponent("donate_data"), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        request.httpMethod = "POST"
        
        request.setValue(token, forHTTPHeaderField: "token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request = addAuthentication(request: request)
        
        // Add the JSON body
        let jsonencoder = JSONEncoder()
        jsonencoder.dateEncodingStrategy = .iso8601
        let deviceListData = try jsonencoder.encode(devices)
        #if DEBUG
        log("DeviceListData \(String(data: deviceListData, encoding: .utf8)!)")
        log("HTTP headers \(String(describing: request.allHTTPHeaderFields))")
        #endif
        request.httpBody = deviceListData
        
        let (data, response) = try await URLSession.shared.asyncData(for: request)

        // Check for errors
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode < 300 else {
            throw API_Error.statusCode(code: (response as? HTTPURLResponse)?.statusCode ?? -1, body: data)
        }
    }
    
    /// Adds authentication and a user-agent to the HTTP request
    /// - Parameter request: a url request that should get the necessary header fields
    /// - Returns: authenticated url request 
    static func addAuthentication(request: URLRequest) -> URLRequest {
        var authenticatedRequest = request
        authenticatedRequest.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        authenticatedRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        //Adding the timezone so we know when a tracker has been found
        if let timezone = TimeZone.current.abbreviation() {
            authenticatedRequest.setValue(timezone, forHTTPHeaderField: "X-Timezone")
        }
        
        return authenticatedRequest
    }
}

enum API_Error: Error {
    case statusCode(code: Int, body: Data)
}

struct API_Response {
    struct Pong: Codable {
        let response: String
    }
    
    struct Token: Codable {
        let token: String
    }
}

struct API_Request {
    struct Device: Codable {
        let uniqueId: String
        let ignore: Bool
        let connectable: Bool
        let firstDiscovery: Date
        let lastSeen: Date
        let deviceType: String
        let beacons: [API_Request.Beacon]
        let notifications: [API_Request.Notification]
    }
    
    struct Beacon: Codable {
        let receivedAt: Date
        let rssi: Int
        let serviceUUIDs: [String]
    }
    
    struct Notification: Codable {
        let falseAlarm: Bool
        let dismissed: Bool
        let clicked: Bool
        let createdAt: Date
        let feedback: Feedback?
    }
    
    struct Feedback: Codable {
        let location: String
    }
}

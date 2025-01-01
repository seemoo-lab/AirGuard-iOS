//
//  ConnectionStatus.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 29.02.24.
//

import Foundation

/// Determines if the device is currently connected to its owner.
enum ConnectionStatus: String {
    
    /// The tracker is connected to at least one device
    case Connected = "CONNECTED"
    
    /// The owner was connected during the last 15 minutes
    case PrematureOffline = "PREMATURE_OFFLINE"
    
    /// The owner was disconnected to the tracker for more than 15 minutes, but less than 8 hours
    case Offline = "OFFLINE"
    
    /// The owner was disconnected to the tracker for more than 8 hours
    case OvermatureOffline = "OVERMATURE_OFFLINE"
    
    /// The owner connection status is unknown
    case Unknown = "UNKNOWN"
    
    /// Textual description of the owner status.
    var description: String {
        
        switch self {
        case .Unknown:
            return "unknown_connection_status"
        
        case .Connected:
            return "owner_connected"
            
        case .PrematureOffline:
            return "owner_premature_offline"
            
        default:
            return "owner_disconnected"
     
        }
    }
    
    /// Returns true if the currect mode might be used for tracking
    func isInTrackingMode() -> Bool {
        
        // If mode is unknown, we need to assume that the tracker might be in tracking mode
        return self == .Unknown ||
        
        // If we know the mode, we only consider offline and overmature offline devices
        self == .Offline || self == .OvermatureOffline
    }
}

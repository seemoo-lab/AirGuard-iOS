//
//  Date.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 17.06.22.
//

import Foundation

extension Date {
    
    /// Returns `true` if the date is older than the seconds specified.
    func isOlderThan(seconds: Double) -> Bool {
        return self.timeIntervalSinceNow  < -seconds
    }
    
    /// Returns the last quarter of an hour. For ex. 15:44 -> 15:30; 10:15 -> 10:15
    func lastFifteenMinutes() -> Date {
        
        let cal = Calendar.current
        let minutes = cal.component(.minute, from: self)
        let seconds = cal.component(.second, from: self)
        
        var roundedMinute = minutes
        
        if minutes < 15 {
            roundedMinute = 0
        } else if minutes < 30 {
            roundedMinute = 15
        } else if minutes < 45 {
            roundedMinute = 30
        } else {
            roundedMinute = 45
        }
        
        let res = cal.date(byAdding: .minute, value: roundedMinute - minutes, to: self)!
        
        return res.addingTimeInterval(-Double(seconds))
    }
}


/// Returns seconds from the amount of days specified.
func daysToSeconds(days: Int) -> Double {
    return Double(days) * 24 * 60 * 60
}


/// Returns seconds from the amount of hours specified.
func hoursToSeconds(hours: Int) -> Double {
    return Double(hours) * 60 * 60
}


/// Returns seconds from the amount of minutes specified.
func minutesToSeconds(minutes: Int) -> Double {
    return Double(minutes) * 60
}

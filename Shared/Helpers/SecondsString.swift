//
//  TimerHelper.swift
//  Timer
//
//  Created by Leon Böttger on 16.06.20.
//  Copyright © 2020 Leon Böttger. All rights reserved.
//

import Foundation

/// Returns a string representing the currentDate - seconds. If `longerDate` is true, the date is spelled out.
func getSimpleSecondsText(seconds: Int, longerDate: Bool = true) -> String {
    
    /// Last 10 seconds - return "now"
    if seconds < 10 && seconds >= 0 {
        return "now".localized()
    }
    
    /// Not older than 1000 seconds - return the relative date, for ex. "4 min ago"
    else if seconds <= 1000 {
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        let currentDate = Date()
        
        return formatter.localizedString(for: currentDate.addingTimeInterval(-Double(seconds)), relativeTo: currentDate)
        
    }
    
    /// Older than 1000 seonds - return the absolute date
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = longerDate ? .long : .short // spell out date or not
    formatter.doesRelativeDateFormatting = true
    
    return formatter.string(from: Date().addingTimeInterval(-Double(seconds)))
}


extension String {
    
    /// Returns the same string with the first letter lowercased
    func lowercaseFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }

    mutating func lowercaseFirstLetter() {
        self = self.lowercaseFirstLetter()
    }
}

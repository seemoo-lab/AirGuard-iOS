//
//  Constants.swift
//  AirGuard
//
//  Created by Leon Böttger on 03.05.22.
//

import Foundation
import SwiftUI


struct Constants {
    
    /// Manual scan will also show devices which were last seen during the last `manualScanBufferTime` seconds before the app was opened
    static let manualScanBufferTime: Double = 200
    
    /// In this interval, the manual scan will be restarted. This enables RSSI update.
    static let scanInterval: Double = 23
    
    /// Maximum width of UI. Relevant for iPad screens.
    static let maxWidth: CGFloat = 700
    
    /// width and height of the icon of a tracker type for manual scan
    static let trackerIconViewSize: CGFloat = 25
    
    /// height of an entry for CustomForm.
    static let SettingsLabelHeight: CGFloat = 55
    
    /// Spacing of sections for CustomForm.
    static let SettingsSectionSpacing: CGFloat = 15
    
    /// Assumed worst RSSI. Used for signal indicator.
    static let worstRSSI: Double = -100
    
    /// Default colors for gradients
    static let defaultColors: [Color] = [.accentColor, Color("LightBlue")]
    
    /// Default height of the button view of BigButtonView.
    static let BigButtonHeight: CGFloat = 80
    
    static let StudyIsActive: Bool = true
}

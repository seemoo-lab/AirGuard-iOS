//
//  TapticControl.swift
//  AirGuard
//
//  Created by Leon Böttger on 20.06.20.
//  Copyright © 2020 Leon Böttger. All rights reserved.
//

import Foundation
import SwiftUI

#if !os(watchOS)
import AudioToolbox
#endif


/// Plays a long vibration on the taptic engine.
func longVibration () -> () {
    DispatchQueue.global(qos: .userInteractive).async {
        
#if !os(watchOS)
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
#else
        WKInterfaceDevice.current().play(.success)
#endif
    }
}


/// Plays a medium vibration on the taptic engine.
func mediumVibration () -> () {
    
    DispatchQueue.global(qos: .userInteractive).async {
#if !os(watchOS)
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
#else
        WKInterfaceDevice.current().play(.click)
#endif
    }
    
}


/// Plays a light vibration on the taptic engine.
func lightVibration () {
    
    DispatchQueue.global(qos: .userInteractive).async {
#if !os(watchOS)
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
#else
        WKInterfaceDevice.current().play(.click)
#endif
    }
    
}


/// Plays a double vibration on the taptic engine.
func doubleVibration () -> () {
    
    DispatchQueue.global(qos: .userInteractive).async {
#if !os(watchOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
#else
        WKInterfaceDevice.current().play(.success)
#endif
    }
    
}


/// Plays an error vibration on the taptic engine.
func errorVibration() -> () {
    
    DispatchQueue.global(qos: .userInteractive).async {
#if !os(watchOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
#else
        WKInterfaceDevice.current().play(.success)
#endif
    }
    
}

//
//  RSSIDecoder.swift
//  AirGuard
//
//  Created by Leon Böttger on 03.05.22.
//

import Foundation
import SwiftUI


/// Converts a RSSI valtue to an integer in [0, 3]. Higher is better.
func RSSIToQuality(percentage: Double) -> Int {

    if (percentage <= 0.75 && percentage > 1) {
        return 3;
    }
    
    if (percentage <= 0.5 && percentage > 0.75) {
        return 2;
    }
    
    if (percentage >= 0.25 && percentage > 0.5) {
        return 1;
    }
    
    return 0;
}

/// Calculates the percentage of the given RSSI in relation to the bestRSSI and the worstRSSI (-100).
func rssiToPercentage(rssi: Double, bestRSSI: Double) -> Double {
    
    let worstRSSI = Constants.worstRSSI
    
    if(rssi == worstRSSI) {
        return 0
    }
    
    let nominalRssi = bestRSSI - worstRSSI
    var signalQuality = (100 *
                         (nominalRssi) *
                         (nominalRssi) -
                         (bestRSSI - rssi) *
                         (15 * (nominalRssi) + 62 * (bestRSSI - rssi))) / ((nominalRssi) * (nominalRssi))
    
    if (signalQuality > 100) {
        signalQuality = 100.0
    } else if (signalQuality < 1) {
        signalQuality = 1.0
    }
    
    let signalQualityNormalized = signalQuality / 100

    return signalQualityNormalized
}

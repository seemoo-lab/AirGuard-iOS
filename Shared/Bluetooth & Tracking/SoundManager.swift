//
//  SoundManager.swift
//  AirGuard
//
//  Created by Leon Böttger on 17.05.22.
//

import Foundation
import CoreBluetooth
import SwiftUI


/// Manages sound playback on trackers
public class SoundManager: ObservableObject {
    
    /// Shows if a sound is requested, but not yet sent to device
    @Published var soundRequest = false
    
    /// Shows that a sound is played on device
    @Published var playingSound = false
    
    /// Shows that an error occured last time playing a sound
    @Published var error: SoundError?
    
    /// The associated tracker constants
    private var constants: TrackerConstants.Type? = nil
    
    /// The Bluetooth UUID of the device to play the sound on.
    private var bluetoothUUID: String? = nil
    
    /// Queue which handles wait for signal of device
    private let waitForSoundQueue = DispatchQueue(label: "waitForSoundQueue")
    
    /// Timeout for playSound in seconds, if device could not be connected
    private let connectTimeout = 30
    
    /// DispatchWorkItem which sets playingSound to false after sound playback is assumed to be over
    private var stoppedPlayingSound = DispatchWorkItem(block: {})
    
    
    /// Tries to play a sound on the given device
    func playSound(constants: TrackerConstants.Type, bluetoothUUID: String?) {
        
        self.constants = constants
        self.bluetoothUUID = bluetoothUUID
        
        if(!soundRequest && !playingSound) {
            
            // cancel if multiple sound requests started consequentely
            stoppedPlayingSound.cancel()
            
            startQueue()
            
            withAnimation {
                playingSound = false
                error = nil
                soundRequest = true
            }
        }
    }
    
    
    /// Starts the queue and periodically tries to connect to the device
    private func startQueue() {
        waitForSoundQueue.async {
            
            if !self.tryToPlay() {
                self.soundNotPlayed(error: .couldNotConnect)
            }
        }
    }
    
    
    /// Gets called if characteristic was written, but not acknowledged
    private func soundNotPlayed(error: SoundError) {
        
        DispatchQueue.main.async {
            errorVibration()
            
            withAnimation {
                self.error = error
                self.soundRequest = false
            }
        }
    }
    
    
    /// Gets called if Bluetooth manager gets positive feedback
    private func playedSound() {
        
        guard let constants = constants else { return }
        
        doubleVibration()
        
        DispatchQueue.main.async {
            withAnimation {
                self.soundRequest = false
                self.playingSound = true
            }
        }
        
        stoppedPlayingSound = DispatchWorkItem(block: {
            withAnimation {
                self.playingSound = false
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(constants.soundDuration ?? 0), execute: stoppedPlayingSound)
    }
    
    
    /// Tries to request sound playback. Returns true if request was sent.
    private func tryToPlay() -> Bool {
        
        guard let constants = constants else { return false }
        guard let id = bluetoothUUID else { return false }
        
        let soundService = constants.soundService
        let soundCharacteristic = constants.soundCharacteristic
        let startCommand = constants.soundStartCommand
        
        if let soundService = soundService, let soundCharacteristic = soundCharacteristic, let startCommand = startCommand, let data = startCommand.hexadecimal {
            
            PersistenceController.sharedInstance.modifyDatabaseBackground { context in
                BluetoothManager.sharedInstance.addRequest(request: BluetoothRequest.writeCharacteristic(deviceID: id, serviceID: soundService, characteristicID: soundCharacteristic, data: data, callback: { state in
                    switch state {
                        
                    case .Success:
                        self.playedSound()
                    case .Timeout:
                        self.soundNotPlayed(error: .couldNotConnect)
                    case .Failure:
                        self.soundNotPlayed(error: .playbackFailed)
                    }
                }))
            }
             
            return true
        }
        else {
            return false
        }
    }
}


/// Stores sound playback error
enum SoundError {
    
    /// The playback failed. Tracker does not allow playback.
    case playbackFailed
    
    /// Could not connect. Tracker out of range.
    case couldNotConnect
    
    /// The title of the error, visible to user
    var title: String {
        switch self {
        case .playbackFailed:
            return "playback_failed".localized()
        case .couldNotConnect:
            return "couldnt_connect".localized()
        }
    }
    
    /// The description of the error, visible to user
    var description: String {
        switch self {
        case .playbackFailed:
            return "playback_failed_description".localized()
        case .couldNotConnect:
            return "couldnt_connect_description".localized()
        }
    }
}

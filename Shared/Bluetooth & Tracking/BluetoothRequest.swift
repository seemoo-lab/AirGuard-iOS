//
//  BluetoothRequest.swift
//  AirGuard
//
//  Created by Leon Böttger on 19.06.22.
//

import Foundation
import CoreBluetooth


/// Stores data of a request to the Bluetooth manager.
struct BluetoothRequest: Equatable, Identifiable {
    
    /// Compares two requests
    static func == (lhs: BluetoothRequest, rhs: BluetoothRequest) -> Bool {
        lhs.id == rhs.id
    }
        
    /// Creates a Bluetooth request which probes the connection to a given device
    static func probeConnect(deviceID: String, callback: @escaping (BluetoothRequestState) -> Void) -> BluetoothRequest {
        return BluetoothRequest(deviceID: deviceID, serviceID: nil, characteristicID: nil, data: nil, callback: {state, data in callback(state)}, operation: .ProbeConnect)
    }
        
    /// Creates a Bluetooth request which probes the connection to a given device
    static func probeService(deviceID: String, serviceID: String, callback: @escaping (BluetoothRequestState) -> Void) -> BluetoothRequest {
        return BluetoothRequest(deviceID: deviceID, serviceID: serviceID, characteristicID: nil, data: nil, callback: {state, data in callback(state)}, operation: .ProbeService)
    }
    
    /// Creates a Bluetooth request which reads a characteristic of a given device
    static func readCharacteristic(deviceID: String, serviceID: String, characteristicID: String, callback: @escaping (BluetoothRequestState, Data?) -> Void) -> BluetoothRequest {
        return BluetoothRequest(deviceID: deviceID, serviceID: serviceID, characteristicID: characteristicID, data: nil, callback: callback, operation: .ReadCharacteristic)
    }
    
    /// Creates a Bluetooth request which writes to a characteristic of a given device
    static func writeCharacteristic(deviceID: String, serviceID: String, characteristicID: String, data: Data, callback: @escaping (BluetoothRequestState) -> Void) -> BluetoothRequest {
        return BluetoothRequest(deviceID: deviceID, serviceID: serviceID, characteristicID: characteristicID, data: data, callback: {state, data in callback(state)}, operation: .WriteCharacteristic)
    }
        
    /// Private initializer
    private init(deviceID: String, serviceID: String?, characteristicID: String?, data: Data?, callback: @escaping (BluetoothRequestState, Data?) -> Void, operation: BluetoothRequestOperation) {
        self.deviceID = deviceID
        self.serviceID = serviceID
        self.characteristicID = characteristicID
        self.data = data
        self.callback = callback
        self.operation = operation
    }
    
    /// The ID of the request
    var id = UUID()
    
    /// The current Bluetooth ID of the device
    let deviceID: String
    
    /// The service of the request. Nil if only the connection status of the device is needed
    let serviceID: String?
    
    /// The characteristic of the request. Nil if only services are checked for availability
    let characteristicID: String?
    
    /// The data to write. Nil for read operations.
    let data: Data?
    
    /// The callback if the request is done
    let callback: (BluetoothRequestState, Data?) -> Void
    
    /// Makes semantics of request clear
    var operation: BluetoothRequestOperation
}


/// All possible operations for a BluetoothRequest
enum BluetoothRequestOperation {
    
    /// Check if device is reachable
    case ProbeConnect
    
    /// Check if a service is present on a device
    case ProbeService
    
    /// Write a given characteristic
    case WriteCharacteristic
    
    /// Read the value of a characteristic
    case ReadCharacteristic
}


/// The return value of the callback for a BluetoothRequest
enum BluetoothRequestState {
    
    /// The request was performed successfully.
    case Success
    
    /// The request timed out and did not finish.
    case Timeout
    
    /// The request failed.
    case Failure
}

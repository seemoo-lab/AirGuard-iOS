//
//  FMDNOwnerOperations.swift
//  AirGuard
//
//  Created by Leon Böttger on 23.09.24.
//

import Foundation
import CommonCrypto
import CryptoKit
import SwiftUI

class FMDNOwnerOperations: ObservableObject {
    
    var recoveryKey: Data? = nil
    var ringingKey: Data? = nil
    var trackingKey: Data? = nil
    
    var ephemeralIdentityKey: Data? = nil
    var accountKey: Data? = nil

    let tracker: BaseDevice
    
    @Published var didSetKeys = false

    init(tracker: BaseDevice) {
        self.tracker = tracker
    }
    
    func generateKeys(ephemeralIdentityKeyHex: String, accountKeyHex: String) {
        
        self.ephemeralIdentityKey = ephemeralIdentityKeyHex.hexadecimal
        self.accountKey = accountKeyHex.hexadecimal
        
        do {
            recoveryKey = try calculateTruncatedSHA256(identityKeyHex: ephemeralIdentityKeyHex, operation: 0x01)
            ringingKey = try calculateTruncatedSHA256(identityKeyHex: ephemeralIdentityKeyHex, operation: 0x02)
            trackingKey = try calculateTruncatedSHA256(identityKeyHex: ephemeralIdentityKeyHex, operation: 0x03)
            
            log("Generated Keys: \(recoveryKey!.hexEncodedString()) \(ringingKey!.hexEncodedString()) \(trackingKey!.hexEncodedString())")
            
            withAnimation {
                didSetKeys = true
            }
        } catch {
            log(error.localizedDescription)
        }
    }
    

    func calculateTruncatedSHA256(identityKeyHex: String, operation: UInt8) throws -> Data {
        guard let identityKeyBytes = identityKeyHex.hexadecimal else {
            throw NSError(domain: "Invalid hex string", code: 0, userInfo: nil)
        }

        var data = identityKeyBytes
        data.append(operation)

        let sha256Hash = SHA256.hash(data: data)
        let truncatedHash = sha256Hash.prefix(8)
        
        return Data(truncatedHash)
    }
    
    
    func executeReadStateOperation(callback: @escaping (String) -> ()) {
        let constructOperationData: (Data) -> Data? = { [self] data in
            return self.constructReadBeaconParametersData(authenticationData: data, accountKey: accountKey!)
        }
        
        let resultCallback: (String) -> () = { [self] result in
            
            if let data = result.hexadecimal {
                let bytes = Array(data)
                
                // Drop length and authentication data
                let encryptedState = Array(bytes.dropFirst(10))
                
                if let accountKey = accountKey, let decryptedBytes = aesDecrypt(data: Data(encryptedState), key: accountKey) {
                    
                    // Remove AES padding and generate string
                    let decryptedHex = Data(decryptedBytes.dropLast(8)).hexEncodedString()
                    log("Decrypted text (hex): \(decryptedHex)")
                    
                    callback(decryptedHex)
                } else {
                    log("Decryption failed")
                }
            }
            
        }
        
        executeFmdnOperation(constructOperationData: constructOperationData, resultCallback: resultCallback)
    }
    
    
    func executeRingerOperation() {
        let constructOperationData: (Data) -> Data? = { [self] data in
            return self.constructRingTrackerOperationData(authenticationData: data, operationKey: ringingKey!)
        }
        
        executeFmdnOperation(constructOperationData: constructOperationData)
    }
    
    
    func executeEnableTrackingProtectionModeOperation() {
        let constructOperationData: (Data) -> Data? = { [self] data in
            return self.constructEnableTrackerModeOperationData(authenticationData: data, operationKey: trackingKey!)
        }
        
        executeFmdnOperation(constructOperationData: constructOperationData)
    }
    
    
    func executeDisableTrackingProtectionModeOperation() {
        let constructOperationData: (Data) -> Data? = { [self] data in
            return self.constructDisableTrackerModeOperationData(authenticationData: data, operationKey: trackingKey!)
        }
        
        executeFmdnOperation(constructOperationData: constructOperationData)
    }
    
    
    func executeFmdnOperation(constructOperationData: @escaping (Data) -> Data?, resultCallback: @escaping (String) -> () = { _ in }) {
        
        let fastPairService = "FE2C"
        let fastPairCharacteristic = "FE2C1238-8366-4814-8EB0-01DE32100BEA"
        let request = BluetoothRequest.readCharacteristic(deviceID: tracker.currentBluetoothId!, serviceID: fastPairService, characteristicID: fastPairCharacteristic, stayConnected: true) { state, data in
            
            if let data = data, let payloadData = constructOperationData(data) {
                
                log("Authentication Data: \(data.hexEncodedString()) - Operation Data: \(payloadData.hexEncodedString()) ")
                
                let request2 = BluetoothRequest.writeReadCharacteristic(deviceID: self.tracker.currentBluetoothId!, serviceID: fastPairService, characteristicID: fastPairCharacteristic, data: payloadData) { state, data in
                    
                    log("Was successful: \( state == .Success)")
                    
                    if let encodedData = data?.hexEncodedString() {
                        
                        log("Data: \(encodedData)")
                        resultCallback(encodedData)
                    }
                }
                
                BluetoothManager.sharedInstance.addRequest(request: request2)
            }
            else {
                log("Could not read authentication data!")
            }
        }
        
        BluetoothManager.sharedInstance.addRequest(request: request)
    }
    
    
    func constructEnableTrackerModeOperationData(authenticationData: Data, operationKey: Data) -> Data? {
        
        // Opcode for enabling tracker mode
        let dataID: UInt8 = 0x07
        
        return constructOperationData(authenticationData: authenticationData, operationKey: operationKey, dataID: dataID, additionalData: Data([0x01]))
    }
    
    
    func constructDisableTrackerModeOperationData(authenticationData: Data, operationKey: Data) -> Data? {
        
        // Opcode for disabling tracker mode
        let dataID: UInt8 = 0x08
        
        let nonce = splitAuthenticationData(authenticationData: authenticationData).1
        
        var dataToHash = ephemeralIdentityKey
        dataToHash?.append(nonce)
        
        let sha256Hash = SHA256.hash(data: dataToHash!)
        let truncatedHash = sha256Hash.prefix(8)
        
        return constructOperationData(authenticationData: authenticationData, operationKey: operationKey, dataID: dataID, additionalData: Data(truncatedHash))
    }
    
    
    func constructReadBeaconParametersData(authenticationData: Data, accountKey: Data) -> Data? {
        
        // Opcode for disabling tracker mode
        let dataID: UInt8 = 0x00
        
        return constructOperationData(authenticationData: authenticationData, operationKey: accountKey, dataID: dataID)
    }
    
    
    func constructRingTrackerOperationData(authenticationData: Data, operationKey: Data) -> Data? {
        
        // Data ID for "Ring"
        let dataID: UInt8 = 0x05
     
        // Additional data is always 0xFF025800
        let additionalData: [UInt8] = [0xFF, 0x02, 0x58, 0x00]
        
        return constructOperationData(authenticationData: authenticationData, operationKey: operationKey, dataID: dataID, additionalData: Data(additionalData))
    }
    
    
    func splitAuthenticationData(authenticationData: Data) -> (UInt8, Data) {
        let protocolMajorVersion = authenticationData[0]
        let nonce = authenticationData.subdata(in: 1..<9)
        
        return (protocolMajorVersion, nonce)
    }
    

    func constructOperationData(authenticationData: Data, operationKey: Data, dataID: UInt8, additionalData: Data? = nil) -> Data? {
      
        let split = splitAuthenticationData(authenticationData: authenticationData)
        
        let protocolMajorVersion = split.0
        let nonce = split.1
        
        // Data length includes the length of the MAC and additional data
        let dataLength: UInt8 = UInt8(8 + (additionalData?.count ?? 0))
        
        // Compute HMAC-SHA256
        var message = Data()
        message.append(protocolMajorVersion)
        message.append(nonce)
        message.append(dataID)
        message.append(dataLength)
        
        if let additionalData = additionalData {
            message.append(contentsOf: additionalData)
        }
        
        var hmac = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        hmac.withUnsafeMutableBytes { hmacBytes in
            message.withUnsafeBytes { messageBytes in
                operationKey.withUnsafeBytes { operationKeyBytes in
                    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), operationKeyBytes.baseAddress, operationKey.count, messageBytes.baseAddress, message.count, hmacBytes.baseAddress)
                }
            }
        }
        
        // Take the first 8 bytes of the HMAC
        let oneTimeAuthKey = hmac.prefix(8)

        
        // Construct the final data object
        var dataObject = Data()
        dataObject.append(dataID)
        dataObject.append(dataLength)
        dataObject.append(oneTimeAuthKey)
        
        if let additionalData = additionalData {
            dataObject.append(contentsOf: additionalData)
        }
        
        return dataObject
    }
    
    func aesDecrypt(data: Data, key: Data) -> Data? {
        let keyLength = kCCKeySizeAES128
        let dataLength = data.count
        let cryptLength = dataLength + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)
        
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode + kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, keyLength,
                        nil,
                        dataBytes.baseAddress, dataLength,
                        cryptBytes.baseAddress, cryptLength,
                        &numBytesDecrypted
                    )
                }
            }
        }
        
        if cryptStatus == kCCSuccess {
            cryptData.removeSubrange(numBytesDecrypted..<cryptData.count)
            return cryptData
        } else {
            return nil
        }
    }
}

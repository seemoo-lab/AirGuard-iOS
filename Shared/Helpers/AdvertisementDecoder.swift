//
//  AdvertisementDecoder.swift
//  AirGuard
//
//  Created by Leon Böttger on 14.05.22.
//

import CoreBluetooth


/// Extracts the service data as hex string from the advertisement data.
func getServiceData(advertisementData: [String : Any], key: String) -> String? {
    let servData = advertisementData[CBAdvertisementDataServiceDataKey]
    
    if let servData = servData as? [CBUUID : Data] {
        if let data = servData[CBUUID(string: key)] {
            
            let hex = data.hexEncodedString()
            
            return hex
        }
    }
    return nil
}


/// Extracts all service data keys as hex strings from the advertisement data.
func getServiceDataKeys(advertisementData: [String : Any]) -> [String] {
    let servData = advertisementData[CBAdvertisementDataServiceDataKey]
    
    if let servData = servData as? [CBUUID : Data] {
        
        return servData.keys.map({$0.uuidString})
    }
    return []
}


extension Data {
    
    /// Returns a string in hex format from this Data.
    func hexEncodedString() -> String {
        let format = "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}


/// Creates a Data object from hex string. Non-hex characters are ignored. String MUST NOT start with "0x...". Returns data represented by this hexadecimal string.
extension String {
    
    var hexadecimal: Data? {
        
        /// capacity is specified in bytes, so divide string length by two
        var data = Data(capacity: Int(ceil(Double(count) / 2)))
        
        /// search for 0-9 and a-f. Try to get two characters, else one.
        let regex = try? NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        
        /// go through results of regex
        regex?.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            
            if let match = match {
                
                /// generate string of one or two characters (=byte)
                let byteString = (self as NSString).substring(with: match.range)
                
                /// convert string to byte
                if let byte = UInt8(byteString, radix: 16) {
                    data.append(byte)
                }
            }
        }
        
        /// no valid data could be generated
        guard data.count > 0 else { return nil }
        
        /// return generated data
        return data
    }
}


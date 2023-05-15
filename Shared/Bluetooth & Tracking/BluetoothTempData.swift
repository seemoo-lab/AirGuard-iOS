//
//  BluetoothTempData.swift
//  AirGuard
//
//  Created by Leon Böttger on 15.10.22.
//

import Foundation
import CoreBluetooth

/// A class containing data of a Bluetooth device which is reset after every app start
class BluetoothTempData: ObservableObject {
    
    /// The queue to syncronize access to all `BluetoothTempData` instances
    private let queue = DispatchQueue(label: "BluetoothTempDataQueue")
    
    
    /// The initializer. Needs to be provided with the Bluetooth UUID
    init(identifier: String) {
        self._identifier = identifier
    }
    
    /// ------------------------------------------------------------------------- //
    
    /// The Bluetooth UUID of the peripheral - Thread safe
    var identifier_background: String {
        queue.sync {
            _identifier
        }
    }
    private let _identifier: String
    
    /// ------------------------------------------------------------------------- //
    
    /// The peripheral associated with this device - Thread safe
    var peripheral_background: CBPeripheral? {
        set(newValue) {
            queue.sync {
                _peripheral = newValue
            }
        }
        get {
            queue.sync {
                _peripheral
            }
        }
    }
    private var _peripheral: CBPeripheral?

    /// ------------------------------------------------------------------------- //
    
    /// The RSSI value of the device. - Thread safe
    var rssi_background: Double {
        set(newValue) {
            queue.sync {
                _rssi = newValue
                
                DispatchQueue.main.async {
                    self.rssi_publisher = newValue
                }
            }
        }
        get {
            queue.sync {
                _rssi
            }
        }
    }
    private var _rssi = Constants.worstRSSI
    
    /// The RSSI value of the device. Published for UI.
    @Published var rssi_publisher = Constants.worstRSSI

    /// ------------------------------------------------------------------------- //
    
    /// The last advertisement data of the device - Thread safe
    var advertisementData_background: [String : Any] {
        set(newValue) {
            queue.sync {
                _advertisementData = newValue
                
                DispatchQueue.main.async {
                    self.advertisementData_publisher = newValue
                }
            }
        }
        get {
            queue.sync {
                _advertisementData
            }
        }
    }
    private var _advertisementData: [String : Any] = [:]
    
    /// The last advertisement data of the device. Published for UI.
    @Published var advertisementData_publisher: [String : Any] = [:]
    
    /// ------------------------------------------------------------------------- //
    
    /// Specifies if the device is connected - Thread safe
    var connected_background: Bool {
        set(newValue) {
            queue.sync {
                _connected = newValue
            }
        }
        get {
            queue.sync {
                _connected
            }
        }
    }
    private var _connected = false
    
    /// ------------------------------------------------------------------------- //

    /// States if the Bluetooth Manager tries to connect to the device to find out about the services
    /// Relevant for AirTags and Find My devices. - Thread safe
    var connecting_background: Bool {
        set(newValue) {
            queue.sync {
                _connecting = newValue
            }
        }
        get {
            queue.sync {
                _connecting
            }
        }
    }
    private var _connecting = false
}

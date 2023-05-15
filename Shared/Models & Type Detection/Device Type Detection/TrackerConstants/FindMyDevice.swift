//
//  FindMyDevice.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 06.06.22.
//

import SwiftUI
import CoreData

final class FindMyDeviceConstants: TrackerConstants {
    
    override class var name: String { "find_my_device".localized() }
    
    override class var offeredService: String { "FD43" }
    
    override class var soundService: String? { "FD44" }
    
    override class var soundCharacteristic: String? { "4F860003-943B-49EF-BED4-2F730304427A" }
    
    override class var soundStartCommand: String? { "01 00 03" }
    
    override class var soundDuration: Int? { 30 }
    
    override class var bestRSSI: Int { -41 }
    
    override class var supportURL: String? { "https://support.apple.com/en-us/HT212227" }
    
    override class var iconView: AnyView {
        AnyView(FindMyIcon())
    }
    
    override class func detect(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        
        if(baseDevice.bluetoothTempData().peripheral_background?.name == "Find My Accessory") {
            
            setType(device: baseDevice, type: .FindMyDevice, context: context)
            retrieveFindMyName(device: baseDevice, context: context)
        }
        
        else {
            detectAirTagsAndFindMyDevices(baseDevice: baseDevice, detectService: offeredService, context: context) { baseDevice, context in
                setType(device: baseDevice, type: .FindMyDevice, context: context)
                retrieveFindMyName(device: baseDevice, context: context)
            }
        }
    }
    
    override class func discoveredAgain(baseDevice: BaseDevice, context: NSManagedObjectContext) {
        
        // Try to retrieve name again
        retrieveFindMyName(device: baseDevice, context: context)
    }
    
    /// special features of Find My devices:
    
    /// info service: provides name of device, for example
    static let infoService = "87290102-3C51-43B1-A1A9-11B9DC38478B"
    
    /// name characistic stores device model name
    static let nameCharacteristic = "6AA50003-6352-4D57-A7B4-003A416FBB0B"
    
    override class var canPlaySound: Bool {
        let iOSVersion = UIDevice.current.systemVersion
        let versionsplit = iOSVersion.split(separator: ".")
        let majorVersion = Int(versionsplit.first ?? "1") ?? 1
        let minorVersion: Int = {
            if versionsplit.count >= 2 {
                return Int(versionsplit[1]) ?? 0
            }
            return 0
        }()
        
        
        let systemVersionSupportsFindMySound = majorVersion < 16 || (majorVersion > 16 && minorVersion < 1)
        
        return systemVersionSupportsFindMySound
    }
}


/// Method to read the model name of Find My devices
func retrieveFindMyName(device: BaseDevice, context: NSManagedObjectContext) {
    
    if let id = device.currentBluetoothId, device.name == nil {
        
        let objID = device.objectID
        
            let request = BluetoothRequest.readCharacteristic(deviceID: id, serviceID: FindMyDeviceConstants.infoService, characteristicID: FindMyDeviceConstants.nameCharacteristic, callback: { state, data in
                
                if state == .Success, let data = data {
                    
                    // very important - we need to refetch device since we now are on a different context
                    modifyDeviceOnBackgroundThread(objectID: objID) { context, device in
                        
                        device.setName(name: String(decoding: data, as: UTF8.self))
                    }
                }
            })
            
            BluetoothManager.sharedInstance.addRequest(request: request)
    }
}


struct FindMyIcon: View {
    
    var body: some View {
        Circle()
            .overlay( GeometryReader { geo in
                ZStack {
                    
                    Pie(start: 360 - 25 - 90, end: 25 - 90)
                        .foregroundColor(.white)
                        .padding(2)
                    
                    Circle()
                        .frame(width: geo.size.width*0.3)
                        .foregroundColor(.white)
                    
                    Circle()
                        .frame(width: geo.size.width*0.2)
                        .foregroundColor(.accentColor)
                }
            })
            .modifier(TrackerIconView(text: ""))
    }
}


struct Pie: Shape {
    var start: Double
    var end: Double
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center =  CGPoint(x: rect.size.width/2, y: rect.size.width/2)
        let radius = rect.size.width/2
        let startAngle = Angle(degrees: start)
        let endAngle = Angle(degrees: end)
        let lineWidth = radius * 0.45
        
        p.addArc(center: center, radius: abs(lineWidth - radius), startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.addArc(center: center, radius: radius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        p.closeSubpath()
        return p
    }
}


struct Previews_FindMyDevice_Previews: PreviewProvider {
    static var previews: some View {
        FindMyIcon()
    }
}

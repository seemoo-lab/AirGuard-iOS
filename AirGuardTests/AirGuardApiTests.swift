//
//  AirGuardTests.swift
//  AirGuardTests
//
//  Created by Alex - SEEMOO on 26.01.23.
//

import XCTest
@testable import AirGuard

final class AirGuardTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPingServer() async throws {
        let available = await API.pingServer()
        XCTAssertTrue(available, "Is the server running at localhost?")
    }
    
    func testGetToken() async throws {
        do {
            let token = try await API.getToken()
            print("Received token \(token)" )
        }catch {
            XCTFail("Is the server running at localhost?")
        }
    }
    
    func testDonateData() async throws {
        
        let demoData = API_Request.Device(
            uniqueId: UUID().uuidString,
            ignore: false,
            connectable: false,
            firstDiscovery: Date(),
            lastSeen: Date(),
            deviceType: "AIRTAG",
            beacons: [
                API_Request.Beacon(receivedAt: Date(), rssi: 0, serviceUUIDs: [], connectionState: ConnectionStatus.Unknown.rawValue)
            ],
            notifications: [
                API_Request.Notification(falseAlarm: false, dismissed: false, clicked: true, createdAt: Date(), feedback: API_Request.Feedback(location: "House"))
            ])
        
        do {
            let token = "9ce39f811f1d2235e68168e6b1d80eadac6659c012eafe078d09b5de68117bd2"
            try await API.donateData(token: token, devices: [demoData])
        }catch {
            XCTFail("Is the server running at localhost?")
        }
    }
    
    func testStatisicalDataUpload() async throws {
        Settings.sharedInstance.participateInStudy = true 
        
        var sendStatsController = SendStatisticsController(lastDataDonation: .distantPast, donorToken: "9ce39f811f1d2235e68168e6b1d80eadac6659c012eafe078d09b5de68117bd2")
        
        try await sendStatsController.sendStats()
    }

}

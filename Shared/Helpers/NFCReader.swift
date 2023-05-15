//
//  NFCReader.swift
//  AirGuard
//
//  Created by Leon Böttger on 02.05.22.
//

import Foundation
import CoreNFC
import UIKit

/// Handles the reading of NFC chips.
class NFCReader: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {

    /// The current active NFC session.
    var session: NFCNDEFReaderSession?
    
    /// The read data.
    @Published var scannedData: Data?
    
    /// The shared instance.
    static var sharedInstance = NFCReader()
    
    /// The initializer.
    private override init() {
        super.init()
    }
    
    
    /// Starts a reading session.
    func scan(infoMessage: String) {
        // Create a reader session and pass self as delegate
        let session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        session.alertMessage = infoMessage
        session.begin()

        log("Scanning NFC!")
    }
    
    
    /// Gets called if any error occured.
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        log(error.localizedDescription)
    }
    
    
    /// Gets called if any NFC tag was detected. Connects to it and reads content.
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        log("Detected Tag!")
        
        for tag in tags {
            session.connect(to: tag) { error in
            
                log("Connected")
                
                if let error = error {
                    log(error.localizedDescription)
                }

                tag.readNDEF(completionHandler: { message, error in
                    log("Read NDEF")
                    
                    if let error = error {
                        log(error.localizedDescription)
                    }
                    
                    if let message = message {
                        self.readerSession(session, didDetectNDEFs: [message])
                    }
                })  
            }
        }
    }
    
    
    /// Called if reader session became active.
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        log("Reader session active")
    }
    
    
    /// Gets called if any messages were received from the NFC tag.
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Handle received messages

        for message in messages {
            for record in message.records {
                
                let url = record.wellKnownTypeURIPayload()
                
                if let url = url {
                    openURL(url: url)
                }
            }
        }
        
        session.invalidate()
    }
}


/// Opens an url. Quits app.
func openURL(url: URL) {
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}

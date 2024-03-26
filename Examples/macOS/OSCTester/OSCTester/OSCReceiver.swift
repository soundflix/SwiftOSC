//
//  OSCReceiver.swift
//  OSCTester
//
//  Created by Felix on 25.03.24.
//

import Foundation
import SwiftOSC

class OSCReceiver: ObservableObject, OSCDelegate {
    
    @Published var text: String = ""
    @Published var messageCount: Int = 0
    
    func didReceive(_ message: OSCMessage) {
        DispatchQueue.main.async {
            self.text = message.description
            self.messageCount += 1
        }
    }
    
    func reset() {
        text = ""
        messageCount = 0
    }
}

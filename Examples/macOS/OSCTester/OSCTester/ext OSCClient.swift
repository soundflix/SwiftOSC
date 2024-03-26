//
//  ext OSCClient.swift
//  OSCTester
//
//  Created by Felix on 26.03.24.
//

import Foundation
import SwiftOSC

extension OSCClient {    
    func sendFloat(address: String, AFloat: Float) {
        guard let oscAddress = OSCAddressPattern(address) else { return }
        let message = OSCMessage(oscAddress, Float(AFloat))
        print("out\(message.description)")
        self.send(message)
    }
}

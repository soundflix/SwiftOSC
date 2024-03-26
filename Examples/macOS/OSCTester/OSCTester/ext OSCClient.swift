//
//  ext OSCClient.swift
//  OSCTester
//
//  Created by Felix on 26.03.24.
//

import Foundation
import SwiftOSC

extension OSCClient {
    public func send(_ element: OSCElement) {
        let data = element.oscData
        connection?.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("OSCClient. send error: \(error.localizedDescription)")
//                os_log("Send error: %{Public}@", log: SwiftOSCLog, type: .error, error.debugDescription)
            }
        }))
    }
    
    func sendFloat(address: String, AFloat: Float) {
        guard let oscAddress = OSCAddressPattern(address) else { return }
        let message = OSCMessage(oscAddress, Float(AFloat))
        print("out\(message.description)")
        self.send(message)
    }
}

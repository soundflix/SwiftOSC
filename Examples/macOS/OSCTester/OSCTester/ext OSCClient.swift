//
//  ext OSCClient.swift
//  OSCTester
//
//  Created by Felix on 26.03.24.
//

import Foundation
import SwiftOSC

extension OSCClient {       
    func push() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            self.sendFloat(address: "/1", AFloat: 1.0)
            self.sendFloat(address: "/1", AFloat: 1.0)
        }
    }
}

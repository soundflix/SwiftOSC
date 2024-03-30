//
//  ext OSCClient.swift
//  OSCTester
//
//  Created by Felix on 26.03.24.
//

import Foundation
import SwiftOSC

extension OSCClient {       
    func push(_ page: TotalMixPage) {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            self.sendFloat(address: page.rawValue, AFloat: 1.0)
            self.sendFloat(address: page.rawValue, AFloat: 1.0)
        }
    }
    
    enum TotalMixPage: String {
        case page1 =  "/1"
        case page2 =  "/2"
        case page3 =  "/3"
        
        var address: OSCAddress {
            OSCAddress(self.rawValue)!
        }
    }
}

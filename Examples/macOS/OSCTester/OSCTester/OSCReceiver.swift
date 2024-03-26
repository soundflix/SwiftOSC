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
    
    func didReceive(_ message: OSCMessage) {
        DispatchQueue.main.async {
            self.text = message.description
        }
    }
    
}

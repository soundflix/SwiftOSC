//
//  ext OSCMessage.swift
//  OSCTester
//
//  Created by Felix on 28.03.24.
//

import Foundation
import SwiftOSC

extension OSCMessage {
    static let TMP1Pulse = OSCMessage(OSCAddressPattern("/")!, [Float(0.0)])
    static let TMP3Pulse = OSCMessage(OSCAddressPattern("/3/recordRecordStart")!, [Float(0.0)])
    /*
     // IMPORTANT: while this is a PULSE it also transmits the real record state
     OSCReceiver: b_44 1/3 OSCMessage [Address</3/recordRecordStart> Float<0.0>]
     OSCReceiver: b_44 2/3 OSCMessage [Address</3/recordPlayPause> Float<0.0>]
     OSCReceiver: b_44 3/3 OSCMessage [Address</3/recordStop> Float<0.0>]
     */
}

//
//  OSCReceiver.swift
//  OSCTester
//
//  Created by Felix on 25.03.24.
//

import Foundation
import SwiftOSC

class OSCReceiver: ObservableObject, OSCDelegate {
    
    let localDebug = true // DEBUG
    
    let page: OSCClient.TotalMixPage
    // differentiate RECEIVING != RECEIVING Page X
    var isPageReceiving = false {
        didSet {
//            if !isPageReceiving { print("isPageReceiving = false")}
            isPageReceiveTimer?.invalidate()
            /// withTimeIntervall: 2.05 seems absolute minmum
            isPageReceiveTimer = Timer.scheduledTimer(withTimeInterval: 2.1, repeats: false) { _ in
                self.isPageReceiving = false
            }
        }
    }
    var isPageReceiveTimer: Timer?
    
    @Published var isReceiving = false {
        didSet {
            if !isReceiving { print("isReceiving = false")}
            receiveTimer?.invalidate()
            /// withTimeIntervall: 2.05 seems absolute minmum
            receiveTimer = Timer.scheduledTimer(withTimeInterval: 2.1, repeats: false) { _ in
                self.isReceiving = false
            }
        }
    }
    var receiveTimer: Timer?
    @Published var text: String = ""
    @Published var messageCount: Int = 0
    
    var bundleNumber = 0
    
    init(for page: OSCClient.TotalMixPage) {
        self.page = page
    }
    
    // FIXME: Design goal: get sender channel (server connection port), identify refresh bundles and their end
    /*
     TotalMix refresh bundles (TM 1.93, 29.03.24):
     # Page 1:
     First:
     b_xx 1/19 OSCMessage [Address</1/labelS1> String<Sub>]
     
     20 bundles 19 18 18 16 16 18 20 19 16 16 15 14 205 16 16 16 15 16 19 1 = 304 messages
     
     Last:
     b_xx 1/1 OSCMessage [Address</1/cue/1/24> Float<0.0>]
     
     # Page 2:
     
     # Page 3:
     First:
     b_xx 1/14 OSCMessage [Address</3/globalMute> Float<1.0>]
     
     5 bundles 14 14 14 14 4 = 60 messages
     
     Last:
     b_xx 4/4 OSCMessage [Address</3/faderGroups/1/1> Float<0.0>]
     
     # Pulse Page 1:
     - bundle 1/1 OSCMessage [Address</> Float<0.0>]
     
     # Pulse Page 3:
     // IMPORTANT: while this is a *triple* PULSE it also transmits the real record state
     OSCReceiver: b_44 1/3 OSCMessage [Address</3/recordRecordStart> Float<0.0>]
     OSCReceiver: b_44 2/3 OSCMessage [Address</3/recordPlayPause> Float<0.0>]
     OSCReceiver: b_44 3/3 OSCMessage [Address</3/recordStop> Float<0.0>]
     
     */
    
    func didReceive(_ data: Data) {
//        print("OSCReceiver: data received \(data.description)")
    }
    
    func didReceive(_ bundle: OSCBundle) {
        // FIXME: set on async main queue may delay internal update?!
        DispatchQueue.main.async {
            self.isReceiving = true
        }
        
        bundleNumber += 1
        let elementCount = bundle.elements.count
        guard let firstMessage = bundle.elements.first as? OSCMessage else { return }
        testForOwnPage(message: firstMessage)
        
        switch elementCount {
        case 1:
            if firstMessage.address == OSCMessage.TMP1Pulse.address {
                Swift.print(".", terminator: "")
                return
            }
            print("OSCReceiver: bundle \(bundleNumber) \(bundle.elements.count)")
        case 3:
            if firstMessage.address == OSCMessage.TMP3Pulse.address {
                print("OSCReceiver: pulse page 3")
                DispatchQueue.main.async {
                    self.isReceiving = true
                }
                return
            }
            print("OSCReceiver: bundle \(bundleNumber) \(bundle.description)")
        default:
            print("OSCReceiver: --- --- --- bundle \(bundleNumber) --- --- ---")
        }
        
        for (index, element) in bundle.elements.enumerated() {
            guard let message = element as? OSCMessage else { return }

            print("OSCReceiver: b_\(bundleNumber) \(index + 1)/\(bundle.elements.count) \(message.description)")
            DispatchQueue.main.async {
                self.text = message.description
                self.messageCount += 1
            }
        }
    }
    
    private func testForOwnPage(message: OSCMessage) {
        if message.address.string.starts(with: page.address.string) {
            isPageReceiving = true
            print("receive matches \(page)")
        }
    }
    
    func didReceive(_ message: OSCMessage) {
//        print("OSCReceiver: message received \(message.description)")
//        DispatchQueue.main.async {
//            self.text = message.description
//            self.messageCount += 1
//        }
    }
    
    func reset() {
        text = ""
        messageCount = 0
    }
}

extension OSCReceiver {
    func print(_ string: String) {
        if localDebug {
            Swift.print(string)
            // Swift.debugPrint(string) // puts all in " quotes. // "Writes the textual representations of the given items most suitable for debugging into the standard output."
        }
    }
}

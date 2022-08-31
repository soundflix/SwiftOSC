//
//  OSCServer.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2019 Devin Roth Music. All rights reserved.
//

import Foundation
import Network

public class OSCServer {
    
    public weak var delegate: OSCDelegate?
    
    public var listener: NWListener?
    public private(set) var port: NWEndpoint.Port
    public private(set) var name: String?
    public private(set) var domain: String?
    public var queue: DispatchQueue = DispatchQueue(label: "SwiftOSC Server", qos: .userInteractive)
    public var connection: NWConnection?
    
    // TODO: why does init have to be failing?
    public init?(port: UInt16, bonjourName: String? = nil, domain: String? = nil) {
        
        self.domain = domain
                
        if let bonjourName = bonjourName {
            self.name = bonjourName
        }
        
//        self.port = NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port.any
        self.port = NWEndpoint.Port(integerLiteral: port)
        
        setupListener()
    }
    
    func setupListener() {
        
        /// listener parameters
        let udpOption = NWProtocolUDP.Options()
        let params = NWParameters(dtls: nil, udp: udpOption)
        params.allowLocalEndpointReuse = true
        params.serviceClass = .signaling // TODO: compare to standard '.best-effort', faster communication?
        
        /// create the listener
        do {
            listener = try NWListener(using: params, on: port)
        } catch let error {
            NSLog("SwiftOSC Server failed to create listener: \(error)")
        }
        
        /// Bonjour service
        if self.name != nil {
            listener?.service = NWListener.Service(name: name,
                                                   type: "_osc._udp",
                                                   domain: domain)
//            listener?.service?.noAutoRename
        }
        
        /// handle incoming connections server will only connect to the latest connection
        listener?.newConnectionHandler = { [weak self] (newConnection) in
            guard let self = self else { print("SwiftOSC Server newConnectionHandler error"); return }
            NSLog("SwiftOSC Server '\(self.name ?? "<noName>")': New Connection from \(String(describing: newConnection))")
            
            /// cancel previous connection // check if it's own port
            if self.connection != nil {
                NSLog("SwiftOSC Server '\(self.name ?? "<noName>")': Cancelling connection: \(String(describing: newConnection))")
                self.connection?.cancel()
            }
            
            self.connection = newConnection
            self.connection?.start(queue: (self.queue))
            self.receive()
        }
                
        /// Handle listener state changes
        listener?.stateUpdateHandler = { [weak self] (newState) in
            guard let self = self else { print("SwiftOSC Server stateUpdateHandler error"); return }
            switch newState {
            case .ready:
                NSLog("SwiftOSC Server '\(self.name ?? "<noName>")': Ready, listening on port \(String(describing: self.listener?.port ?? 0)), delegate: \(String(describing: self.delegate.debugDescription.dropLast(1).dropFirst(9) ))")
            case .failed(let error):
                // there are .dns() and .tls() cases, too
                // [48: Address already in use]
                if case let .posix(errorNumber) = error {
                    NSLog("SwiftOSC Server '\(self.name ?? "<noName>")': Listener failed with \(errorNumber): \(error)")
                } else {
                    NSLog("SwiftOSC Server '\(self.name ?? "<noName>")': Listener failed with \(error)")
                }
                /// wait a little for restart to reduce load
                // TODO: store timer and cancel on next call!
                _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    self.restart()
                }
            case .cancelled:
                NSLog("SwiftOSC Server '\(self.name ?? "<noName>")': Listener cancelled")
            default:
                break
            }
        }
        
        /// start the listener
        listener?.start(queue: queue)
    }
    
    /// receive
    public func receive() {
        connection?.receiveMessage { [weak self] (content, context, isCompleted, error) in
            if let data = content {
                // data.printHexString()
                self?.decodePacket(data)
            }
            
            if error == nil && self?.connection != nil{
                self?.receive()
            }
        }
    }
    
    func decodePacket(_ data: Data){
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.didReceive(data)
        }
        
        if data[0] == 0x2f { // check if first character is "/"
            if let message = decodeMessage(data) {
                // print(message)
                self.sendToDelegate(message)
            }
            
        } else if data.count > 8 { /// make sure we have at least 8 bytes before checking if a bundle.
            if "#bundle\0".toData() == data.subdata(in: Range(0...7)) { // matches string #bundle
                if let bundle = decodeBundle(data){
                    self.sendToDelegate(bundle)
                }
            }
        } else {
            NSLog("Invalid OSCPacket: data must begin with #bundle\\0 or /")
        }
    }
    
    func decodeBundle(_ data: Data)->OSCBundle? {
        
        /// extract timetag
        let bundle = OSCBundle(OSCTimetag(data.subdata(in: 8..<16)))
        
        var bundleData = data.subdata(in: 16..<data.count)
        
        while bundleData.count > 0 {
            let length = Int(bundleData.subdata(in: Range(0...3)).toInt32())
            let nextData = bundleData.subdata(in: 4..<length+4)
            bundleData = bundleData.subdata(in:length+4..<bundleData.count)
            // SwiftOSC isssue OSCServer crashes #52
            // it's not a proper fix since you can have a bundle in a bundle
//            if "#bundle\0".toData() == nextData.subdata(in: Range(0...7)){//matches string #bundle
//                if let newbundle = self.decodeBundle(nextData){
//                    bundle.add(newbundle)
//                } else {
//                    return nil
//                }
//            } else if nextData[0] == 0x2f { // matches /
                
                if let message = self.decodeMessage(nextData) {
                    bundle.add(message)
                } else {
                    return nil
                }
//            } else {
//                NSLog("Invalid OSCBundle: Bundle data must begin with #bundle\\0 or /.")
//                return nil
//            }
        }
        return bundle
    }
    
    func decodeMessage(_ data: Data)->OSCMessage?{
        var messageData = data
        var message: OSCMessage
        
        /// extract address and check if valid
        if let addressEnd = messageData.firstIndex(of: 0x00){
            
            let addressString = messageData.subdata(in: 0..<addressEnd).toString()
            if let address = OSCAddressPattern(addressString) {
                message = OSCMessage(address)
                
                /// extract types
                messageData = messageData.subdata(in: (addressEnd/4+1)*4..<messageData.count)
                
                /// message may not contain arguments
                guard let typeEnd = messageData.firstIndex(of: 0x00) else {
                    NSLog("SwiftOSCServer: Invalid OSCMessage: Missing type terminator.")
                    return message
                }
                let type = messageData.subdata(in: 1..<typeEnd).toString()
                
                messageData = messageData.subdata(in: (typeEnd/4+1)*4..<messageData.count)
                
                for char in type {
                    switch char {
                    case "i": /// int
                        message.add(Int(messageData.subdata(in: Range(0...3))))
                        messageData = messageData.subdata(in: 4..<messageData.count)
                    case "f": /// float
                        message.add(Float(messageData.subdata(in: Range(0...3))))
                        messageData = messageData.subdata(in: 4..<messageData.count)
                    case "s": /// string
                        let stringEnd = messageData.firstIndex(of: 0x00)!
                        message.add(String(messageData.subdata(in: 0..<stringEnd)))
                        messageData = messageData.subdata(in: (stringEnd/4+1)*4..<messageData.count)
                    case "b": /// blob
                        var length = Int(messageData.subdata(in: Range(0...3)).toInt32())
                        messageData = messageData.subdata(in: 4..<messageData.count)
                        message.add(OSCBlob(messageData.subdata(in: 0..<length)))
                        while length%4 != 0 {//remove null ending
                            length += 1
                        }
                        messageData = messageData.subdata(in: length..<messageData.count)
                        
                    case "T": /// true
                        message.add(true)
                    case "F": /// false
                        message.add(false)
                    case "N": /// null
                        message.add()
                    case "I": /// impulse
                        message.add(OSCImpulse())
                    case "t": /// timetag
                        message.add(OSCTimetag(messageData.subdata(in: Range(0...7))))
                        messageData = messageData.subdata(in: 8..<messageData.count)
                    default:
                        NSLog("Invalid OSCMessage: Unknown OSC type.")
                        return nil
                    }
                }
            } else {
                NSLog("Invalid OSCMessage: Invalid address.")
                return nil
            }
            return message
        } else {
            NSLog("Invalid OSCMessage: Missing address terminator.")
            return nil
        }
    }
    
    func sendToDelegate(_ element: OSCElement){
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if let message = element as? OSCMessage {
                strongSelf.delegate?.didReceive(message)
            }
            if let bundle = element as? OSCBundle {
                
                /// send to delegate at the correct time
                if bundle.timetag.secondsSinceNow < 0 {
                    strongSelf.delegate?.didReceive(bundle)
                    for element in bundle.elements {
                        strongSelf.sendToDelegate(element)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + bundle.timetag.secondsSinceNow, execute: {
                        [weak self] in
                            guard let strongSelf = self else { return }
                        strongSelf.delegate?.didReceive(bundle)
                        for element in bundle.elements {
                            strongSelf.sendToDelegate(element)
                        }
                    })
                }
                
            }
        }
    }
    
    /// cancel connection and listener
    public func stop() {
//        connection?.forceCancel()
        connection?.cancel()
        listener?.cancel()
        // listener = nil
    }
    
    /// cancel conection and listener, then start with refreshed settings
    public func restart() {
        stop()
        
        /// setup new listener
        setupListener()
    }
}

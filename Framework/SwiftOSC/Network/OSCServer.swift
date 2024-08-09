//
//  OSCServer.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2019 Devin Roth Music. All rights reserved.
//

import Foundation
import Network
import OSLog

public class OSCServer {
    
    public weak var delegate: OSCDelegate?
    
    public var listener: NWListener?
    public private(set) var port: NWEndpoint.Port
    public private(set) var name: String?
    public private(set) var domain: String?
    public private(set) var queue: DispatchQueue = DispatchQueue(label: "SwiftOSC Server", qos: .userInteractive)
    public var connection: NWConnection?
    /// When this flag is set, the server uses delegate method didReceive(_:port:) instead of didReceive(_:)
    public private(set) var indicatesPort: Bool
    
    // TODO: why does init have to be failing?
    public init?(port: UInt16, bonjourName: String? = nil, delegate: OSCDelegate? = nil, domain: String? = nil, indicatesPort: Bool = false) {
        
        self.delegate = delegate
        self.domain = domain
        
        if let bonjourName = bonjourName {
            self.name = bonjourName
        }
        
        self.port = NWEndpoint.Port(integerLiteral: port)
        self.indicatesPort = indicatesPort
        
        setupListener()
    }
    
    private func setupListener() {
        
        /// listener parameters
        let udpOption = NWProtocolUDP.Options()
        let params = NWParameters(dtls: nil, udp: udpOption)
        params.allowLocalEndpointReuse = true
        params.serviceClass = .signaling // TODO: compare to standard '.best-effort', faster communication?
        
        /// create the listener
        do {
            listener = try NWListener(using: params, on: port)
        } catch let error {
            os_log("Server failed to create listener: %{Public}@", log: SwiftOSCLog, type: .error, String(describing: error))
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
            guard let self = self else { os_log("SwiftOSC Server newConnectionHandler: Error", log: SwiftOSCLog, type: .error); return }
            os_log("Server '%{Public}@': New connection %{Public}@", log: SwiftOSCLog, type: .info, self.name ?? "<noName>", String(describing: newConnection))

            // TODO: check if new connection port is TotalMix
            // if endpoint type: case hostPort(host: NWEndpoint.Host, port: NWEndpoint.Port)
            // query port in Terminal:
            // lsof -i -P | grep -i "UDP localhost:64194"
            // check if returns containing "TotalmixF"

//            switch newConnection {
//            case .init(host: let newRemoteHost, port: let newRemotePort, using: _):
//                print("newRemoteHost:Port: \(newRemoteHost):\(newRemotePort)")
//            case .init(to: _, using: _):
//                break
//            default:
//                break
//            }
            
            /// cancel previous connection // check if it's own port
            if self.connection != nil {
                guard let connection = self.connection else { os_log("Server: Can not cancel NIL connection.", log: SwiftOSCLog, type: .error); return }
                os_log("Server '%{Public}@': Cancelling connection %{Public}@", log: SwiftOSCLog, type: .info, self.name ?? "<noName>", String(describing: connection))
                self.connection?.cancel()
            }
            
            /// start new connection
            self.connection = newConnection
            self.connection?.start(queue: (self.queue))
            self.receive()
        }
                
        /// Handle listener state changes
        listener?.stateUpdateHandler = { [weak self] (newState) in
            guard let self = self else { os_log("Server stateUpdateHandler: Error.", log: SwiftOSCLog, type: .error); return }
            switch newState {
            case .ready:
                os_log("Server '%{Public}@': Ready, listening on port %{Public}@, delegate: %{Public}@", log: SwiftOSCLog, type: .default, self.name ?? "<noName>", String(describing: self.listener?.port ?? 0), String(describing: self.delegate))
            case .failed(let error):
                // there are .dns() and .tls() cases, too
                // [48: Address already in use]
                if case let .posix(errorNumber) = error {
                    os_log("Server '%{Public}@': Listener failed with: %{Public}@: %{Public}@", log: SwiftOSCLog, type: .error, self.name ?? "<noName>", String(describing: errorNumber), String(describing: error))
                } else {
                    os_log("Server '%{Public}@' failed to create listener: %{Public}@", log: SwiftOSCLog, type: .error, self.name ?? "<noName>", String(describing: error))
                }
                /// wait a little with restart to reduce load
                // TODO: store timer and cancel on next call!
                _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    self.restart()
                }
            case .cancelled:
                os_log("Server '%{Public}@': Listener cancelled.", log: SwiftOSCLog, type: .info, self.name ?? "<noName>")
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
        
        // FIXME: What is GCD doing here on 'main'?
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
            os_log("Invalid OSCPacket: data must begin with #bundle\\0 or /", log: SwiftOSCLog, type: .error)
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
//            os_log("Invalid OSCPacket: data must begin with #bundle\\0 or /", log: SwiftOSCLog, type: .error)
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
                    os_log("Server: Invalid OSCMessage: Missing type terminator. Address: %{Public}@", log: SwiftOSCLog, type: .error, message.address.string)
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
                        os_log("Invalid OSCMessage: Unknown OSC type.", log: SwiftOSCLog, type: .error)
                        return nil
                    }
                }
            } else {
                os_log("Invalid OSCMessage: Invalid address.", log: SwiftOSCLog, type: .error)
                return nil
            }
            return message
        } else {
            os_log("Invalid OSCMessage: Missing address terminator", log: SwiftOSCLog, type: .error)
            return nil
        }
    }
    
    func sendToDelegate(_ element: OSCElement){
        
        // FIXME: What is GCD doing here on 'main'?
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let message = element as? OSCMessage {
                if self.indicatesPort {
                    self.delegate?.didReceive(message, port: self.port)
                } else {
                    self.delegate?.didReceive(message)
                }
            }
            
            if let bundle = element as? OSCBundle {
                
                /// send to delegate at the correct time
                if bundle.timetag.secondsSinceNow < 0 {
                    self.delegate?.didReceive(bundle)
                    for element in bundle.elements {
                        self.sendToDelegate(element)
                    }
                } else {
                    // FIXME: What is GCD doing here on 'main'?
                    DispatchQueue.main.asyncAfter(deadline: .now() + bundle.timetag.secondsSinceNow, execute: { [weak self] in
                        guard let self = self else { return }
                        
                        self.delegate?.didReceive(bundle)
                        for element in bundle.elements {
                            self.sendToDelegate(element)
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

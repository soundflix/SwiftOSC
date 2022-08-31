//
//  OSCClient.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2019 Devin Roth Music. All rights reserved.
//

import Foundation
import Network

@available(OSX 10.15, *)
public class OSCClient {

    public var connection: NWConnection?
    var queue: DispatchQueue = DispatchQueue(label: "SwiftOSC Client", qos: .userInteractive)
    public var serviceType: String? = "_osc._udp"
    public var browser: NWBrowser?

    public private(set) var host: NWEndpoint.Host?
    public private(set) var port: NWEndpoint.Port?
    
    public init(serviceType:String) {
            self.serviceType = serviceType

            self.startBrowsing()
        }

    public init(host: String, port: UInt16) {
        var safeHost = host
        /// defaut to localhost (empty string will crash)
        if safeHost == "" {
            safeHost = "127.0.0.1"
        }
        self.host = NWEndpoint.Host(safeHost)

//        self.port = NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port.any
        self.port = NWEndpoint.Port(integerLiteral: port)

        setupConnection()
    }

    /// setup a new connection
    func setupConnection() {

        let params = NWParameters.udp
        params.serviceClass = .signaling // DEBUG: test if this is effectively faster than '.best-effort'
        
        /// create the connection
        if let host = self.host, let port = self.port {
            connection = NWConnection(host: host, port: port, using: params)
        }
            
        /// setup state update handler
        connection?.stateUpdateHandler = stateUpdateHandler(newState:)

        /// start the connection
        connection?.start(queue: queue)

    }
    
    func stateUpdateHandler(newState: NWConnection.State) {
        switch newState {
        case .ready:
            NSLog("SwiftOSC Client is ready. \(String(describing: self.connection))")
        case .failed(let error):
            NSLog("SwiftOSC Client failed with error \(error)")
            NSLog("SWiftOSC Client is restarting.")
            self.setupConnection()
        case .cancelled:
            NSLog("SWiftOSC Client cancelled.")
            break
        case .waiting(let error):
            NSLog("SwiftOSC Client waiting with error \(error)")
        case .preparing:
            NSLog("SWiftOSC Client is preparing.")
            break
        case .setup:
            NSLog("SWiftOSC Client is setting up.")
            break
        @unknown default:
        fatalError()
        }
    }
    
    public func startBrowsing() {
      // TODO
        print("NWBrowser not yet implemented")
    }

    public func send(_ element: OSCElement){

        let data = element.oscData
        connection?.send(content: data, completion: .contentProcessed({ (error) in
            if let error = error {
                NSLog("Send error: \(error)")
            }
        }))
    }
    public func restart() {
//        connection?.forceCancel()
        connection?.cancel()

        setupConnection()
    }
}

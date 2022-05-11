//
//  OSCClient.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2019 Devin Roth Music. All rights reserved.
//

import Foundation
import Network

public class OSCClient {

    public var connection: NWConnection?
    var queue: DispatchQueue
    public var serviceType: String? = "_osc._udp"
    public var browser: NWBrowser?

    public private(set) var host: NWEndpoint.Host?
    public private(set) var port: NWEndpoint.Port?
    
    public init(serviceType:String) {
            self.serviceType = serviceType
//            super.init()
        queue = DispatchQueue(label: "SwiftOSC Client") // better use .main ?
            self.startBrowsing()
        }

    public init(host: String, port: UInt16) {

        self.host = NWEndpoint.Host(host)
        if (1 ... 65535).contains(port) {
            self.port = NWEndpoint.Port(rawValue: port)!
        } else {
            self.port = NWEndpoint.Port(rawValue: 1)!
        }

        queue = DispatchQueue(label: "SwiftOSC Client")
        setupConnection()
    }

    func setupConnection(){

        let params = NWParameters.udp
        params.serviceClass = .signaling // DEBUG: test if this is really faster than '.best-effort'
        
        // create the connection
        if let host = self.host, let port = self.port {
            connection = NWConnection(host: host, port: port, using: params)
            // TODO make custom connection class to reuse with bonjour variant
        }
            
        // setup state update handler
        connection?.stateUpdateHandler = stateUpdateHandler(newState:)
//        connection?.stateUpdateHandler = { [weak self] (newState) in
//            switch newState {
//            case .ready:
//                NSLog("SwiftOSC Client is ready. \(String(describing: self?.connection))")
//            case .failed(let error):
//                NSLog("SwiftOSC Client failed with error \(error)")
//                NSLog("SWiftOSC Client is restarting.")
//                self?.setupConnection()
//            case .cancelled:
//                NSLog("SWiftOSC Client cancelled.")
//                break
//            case .waiting(let error):
//                NSLog("SwiftOSC Client waiting with error \(error)")
//            case .preparing:
//                NSLog("SWiftOSC Client is preparing.")
//                break
//            case .setup:
//                NSLog("SWiftOSC Client is setting up.")
//                break
//            @unknown default:
//            fatalError()
//            }
//        }

        // start the connection
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
        // destroy connection and listener
        connection?.forceCancel()


        // setup new listener
        setupConnection()
    }
}

//
//  OSCClient.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2019 Devin Roth Music. All rights reserved.
//

import Foundation
import Network
import OSLog

public class OSCClient: NSObject, ObservableObject {

    public var connection: NWConnection?
    public private(set) var queue: DispatchQueue = DispatchQueue(label: "SwiftOSC Client", qos: .userInteractive)
    public private(set) var serviceType: String? = "_osc._udp"
    public var browser: NWBrowser?

    public private(set) var host: NWEndpoint.Host?
    public private(set) var port: NWEndpoint.Port?
    
    public init(serviceType:String) {
        self.serviceType = serviceType
        super.init()
        
        self.startBrowsing()
    }
    
    @Published public var connectionState: NWConnection.State = .setup
    @Published public var sendError: NWError?

    public init(host: String, port: UInt16) {
        var safeHost = host
        if safeHost.isEmpty {
            os_log("Invalid Hostname: Can not use empty string. Replacing with 'localhost'", log: SwiftOSCLog, type: .error)
            safeHost = "localhost"
        }
        self.host = NWEndpoint.Host(safeHost)
        self.port = NWEndpoint.Port(integerLiteral: port)
        super.init()
        
        setupConnection()
    }

    /// setup a new connection
    func setupConnection() {

        let params = NWParameters.udp
        params.serviceClass = .signaling
        
        guard let host = self.host, let port = self.port else { return }
        connection = NWConnection(host: host, port: port, using: params)
        connection?.stateUpdateHandler = stateUpdateHandler(newState:)
        connection?.start(queue: queue)

    }
    
    func stateUpdateHandler(newState: NWConnection.State) {
        
        DispatchQueue.main.async {
            self.connectionState = newState
        }
        
        switch newState {
        case .ready:
            guard let connection = self.connection else {
                os_log("Client: Error: Client ready but NIL connection.", log: SwiftOSCLog, type: .error)
                return
            }
            os_log("Client is ready: %{Public}@", log: SwiftOSCLog, type: .default, String(describing: connection))
        case .failed(let error):
            os_log("Client failed with error: %{Public}@", log: SwiftOSCLog, type: .error, error.debugDescription)
            os_log("Send Client is restarting.", log: SwiftOSCLog, type: .info)
            self.setupConnection()
        case .cancelled:
            os_log("Client cancelled.", log: SwiftOSCLog, type: .info)
            break
        case .waiting(let error):
            os_log("Client waiting with error : %{Public}@", log: SwiftOSCLog, type: .error, error.debugDescription)
        case .preparing:
            os_log("Client is preparing.", log: SwiftOSCLog, type: .info)
            break
        case .setup:
            os_log("Client is setting up.", log: SwiftOSCLog, type: .info)
            break
        @unknown default:
            fatalError()
        }
    }
    
    public func startBrowsing() {
      // TODO:
        os_log("NWBrowser not yet implemented", log: SwiftOSCLog, type: .error)
    }
    
    public func send(_ element: OSCElement) {
        let data = element.oscData
        connection?.send(content: data, completion: .contentProcessed({ (error) in
            DispatchQueue.main.async {
                self.sendError = error
            }
            if let error = error {
                os_log("Send error: %{Public}@", log: SwiftOSCLog, type: .error, error.debugDescription)
            } else {
                print("OSC send completion without error")
            }
        }))
    }
    
    public func restart() {
        connection?.cancel()
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            self.setupConnection()
        }
    }
    
    /// Cancel connection and listener, then start with new settings
    public func restart(port: NWEndpoint.Port) {
        connection?.cancel()
        self.port = port
        
        /// Setup new listener
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            self.setupConnection()
        }
    }
}

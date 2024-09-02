//
//  OSCDelegate.swift
//  SwiftOSC
//
//  Created by Devin Roth on 2018-12-01.
//  Copyright © 2019 Devin Roth. All rights reserved.
//

import Foundation
import Network

public protocol OSCDelegate: AnyObject {
    func didReceive(_ data: Data)
    
    /// OSCServer will use this method instead of `didReceive(_ bundle:_ port:)` when set with `indicatePort = false` during `init()` (Default setting)
    func didReceive(_ bundle: OSCBundle)
    /// OSCServer will use this method instead of `didReceive(_ bundle:)` when set with `indicatePort = true` during `init()`
    func didReceive(_ bundle: OSCBundle, port: NWEndpoint.Port)
    
    /// OSCServer will use this method instead of `didReceive(_ message:_ port:)` when set with `indicatePort = false` during `init()` (Default setting)
    func didReceive(_ message: OSCMessage)
    /// OSCServer will use this method instead of `didReceive(_ message:)` when set with `indicatePort = true` during `init()`
    func didReceive(_ message: OSCMessage, port: NWEndpoint.Port)
}

extension OSCDelegate {
    public func didReceive(_ data: Data) {}
    public func didReceive(_ bundle: OSCBundle) {}
    
    public func didReceive(_ message: OSCMessage) {}
    public func didReceive(_ message: OSCMessage, port: NWEndpoint.Port) {}
}

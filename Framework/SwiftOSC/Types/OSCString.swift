//
//  OSCTypes.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2016 Devin Roth Music. All rights reserved.
//

import Foundation

extension String: OSCType {
    public var oscTag: String {
        get {
            return "s"
        }
    }
    public var oscData: Data {
        get {
//            TODO: Remove force unwrap, needs testing!
            var data = self.data(using: String.Encoding.utf8)!
            
            return data.base32NullTerminated()
            
            // proposal:
//            if var data = self.data(using: String.Encoding.utf8) {
//                return data.base32NullTerminated()
//            }
//            if var data = self.data(using: String.Encoding.windowsCP1252) {
//                return data.base32NullTerminated()
//            }
            /// if all else fails, return empty data
//            return Data()
        }
    }
    init(_ data:Data){
        if let dataString = String(data: data, encoding: String.Encoding.utf8) {
            self = dataString
            return
        }
        
        if let dataString = String(data: data, encoding: String.Encoding.windowsCP1252) {
            self = dataString
            return
        }
        
        NSLog("SwiftOSC StringDataError: Unknown encoding in: \(String(describing: data))")
        self = "<OSCStringDataError>"
            
        // self = String(data: data, encoding: String.Encoding.utf8)! // was crashing on german umlaut characters
    }
}

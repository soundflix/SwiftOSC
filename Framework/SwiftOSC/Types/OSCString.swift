//
//  OSCTypes.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2016 Devin Roth Music. All rights reserved.
//

import Foundation
import OSLog

extension String: OSCType {
    public var oscTag: String {
        get {
            return "s"
        }
    }
    public var oscData: Data {
        get {
            if var data = self.data(using: String.Encoding.utf8) {
                return data.base32NullTerminated()
            }
            /// if this fails, try different encoding (fixes german umlaut with RME TotalMix)
            if var data = self.data(using: String.Encoding.windowsCP1252) {
                os_log("String oscData: Decoder type 'windowsCP1252' was used in in: %{Public}@", log: SwiftOSCLog, type: .info, String(describing: self))
                return data.base32NullTerminated()
            }
            /// if all else fails, return empty data
            os_log("Unknown string encoding in data: %{Public}@", log: SwiftOSCLog, type: .error, String(describing: self))
            return Data()
        }
    }
    init(_ data: Data){
        if let dataString = String(data: data, encoding: String.Encoding.utf8) {
            self = dataString
            return
        }
        /// if this fails, try different encoding (fixes german umlaut with RME TotalMix)
        if let dataString = String(data: data, encoding: String.Encoding.windowsCP1252) {
            self = dataString
            os_log("String data: Decoder type 'windowsCP1252' was used in in: %{Public}@", log: SwiftOSCLog, type: .info, String(describing: self))
            return
        }
        os_log("Unknown string encoding in data: %{Public}@", log: SwiftOSCLog, type: .error, String(describing: data))
        self = "<Error:UnknownDataEncoding>"
    }
}

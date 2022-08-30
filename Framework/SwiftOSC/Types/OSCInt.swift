//
//  OSCTypes.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2016 Devin Roth Music. All rights reserved.
//

import Foundation

extension Int: OSCType {
    public var oscTag: String {
        get {
            return "i"
        }
    }
    public var oscData: Data {
        get {
            var int = Int32(self).bigEndian
            let buffer = withUnsafePointer(to: &int) {
                UnsafeBufferPointer(start: $0, count: 1)
            }
            let data = Data(buffer: buffer)
            return data
        }
    }
    init(_ data: Data) {
        var int = Int32()
        let buffer = withUnsafeMutablePointer(to: &int) {
            UnsafeMutableBufferPointer(start: $0, count: 1)
        }
        _ = data.copyBytes(to: buffer)
        
        self =  Int(int.byteSwapped)
    }
}

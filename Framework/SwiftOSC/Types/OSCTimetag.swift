//
//  OSCTypes.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2016 Devin Roth Music. All rights reserved.
//

import Foundation

public typealias OSCTimetag = UInt64

extension OSCTimetag: OSCType {
    public var oscTag: String {
        get {
            return "t"
        }
    }
    public var oscData: Data {
        get {
            var int = self.bigEndian
            let buffer = withUnsafePointer(to: &int) {
                UnsafeBufferPointer(start: $0, count: 1)
            }
            return Data(buffer: buffer)
        }
    }
    public var secondsSince1900: Double {
        get {
            return Double(self / 0x1_0000_0000)
        }
    }
    public var secondsSinceNow: Double {
        get {
            if self > 0 {
                return Double((self - Date().oscTimetag) / 0x1_0000_0000)
            } else {
                return 0.0
            }
        }
    }
    public init(secondsSinceNow seconds: Double){
        self = Date().oscTimetag
        self += UInt64(seconds * 0x1_0000_0000)
    }
    public init(secondsSince1900 seconds: Double){
        self = UInt64(seconds * 0x1_0000_0000)
    }
    init(_ data: Data){
        var int = UInt64()
        let buffer = withUnsafeMutablePointer(to: &int) {
            UnsafeMutableBufferPointer(start: $0, count: 1)
        }
        _ = data.copyBytes(to: buffer)
        
        self =  int.byteSwapped
    }
}

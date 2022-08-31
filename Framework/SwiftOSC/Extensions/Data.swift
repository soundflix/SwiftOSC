//
//  Data.swift
//  SwiftOSC
//
//  Created by Devin Roth on 7/5/16.
//  Copyright © 2019 Devin Roth Music. All rights reserved.
//

import Foundation

extension Data {
    func toInt32() -> Int32 {
        var int = Int32()
        let buffer = withUnsafeMutablePointer(to: &int) {
            UnsafeMutableBufferPointer(start: $0, count: 1)
        }
        _ = self.copyBytes(to: buffer)
        
        return int.byteSwapped
    }
}

extension Data {
    // TODO: Another risky force unwrap
    func toString() -> String {
        return String(data: self, encoding: String.Encoding.utf8)!
    }
}

extension Data {
    public func printHexString() {
        var string = ""
        for byte in self {
            let hex = String(format:"%02X", byte)
            string += hex
        }
        print(string)
    }
}

extension Data {
    /// Returns base 32 null terminated data
    mutating func base32NullTerminated() -> Data {
        for _ in 1...4-self.count%4 {
            var null = UInt8(0)
            self.append(&null, count: 1)
        }
        return self
    }
}

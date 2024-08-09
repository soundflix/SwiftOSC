//
//  POSIXError.swift
//  SwiftOSC
//
//  Created by Felix on 24.04.24.
//  Copyright © 2024 Devin Roth Music. All rights reserved.
//

import Foundation

extension POSIXError {
    // POSIXError.localizedDescription = "The operation couldn’t be completed. Connection refused"
    /// The user-readable POSIX error message and error code.
    var message: String {
        return "\(self.localizedDescription.replacingOccurrences(of: "The operation couldn’t be completed. ", with: "")) (\(self.errorCode))"
    }
}

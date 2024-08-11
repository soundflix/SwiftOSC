//
//  ext State.swift
//  SwiftOSC
//
//  Created by Felix on 26.03.24.
//  Copyright © 2024 Devin Roth Music. All rights reserved.
//

import Foundation
import Network

extension NWConnection.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cancelled:
            return "Cancelled"
        case .setup:
            return "Setup"
        case .waiting(let error):
            return "Waiting (\(error.localizedDescription))"
        case .preparing:
            return "Preparing"
        case .ready:
            return "Ready"
        case .failed(let error):
            if case let .posix(errorNumber) = error {
                /// Returning shorter description
                return "Failed: \(POSIXError(errorNumber).message)"
            } else {
                return "Failed: \(error.localizedDescription)"
            }
        @unknown default:
            return "Unknown"
        }
    }
}

//extension NWConnection.State: RawRepresentable {
//    puplic var rawValue: String {
//        switch self {
//        case .setup:
//            return "Setup"
//        case .waiting(_):
//            return "Waiting"
//        case .preparing:
//            return "Prepa"
//        case .ready:
//            <#code#>
//        case .failed(_):
//            <#code#>
//        case .cancelled:
//            <#code#>
//        @unknown default:
//            <#code#>
//        }
//    }
//}

extension NWListener.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cancelled:
            return "Cancelled"
        case .setup:
            return "Setup"
        case .waiting(let error):
            return "Waiting (\(error.localizedDescription))"
        case .ready:
            return "Ready"
        case .failed(let error):
            if case let .posix(errorNumber) = error {
                /// Returning shorter description
                return "Failed: \(POSIXError(errorNumber).message)"
            } else {
                return "Failed: \(error.localizedDescription)"
            }
        @unknown default:
            return "Unknown"
        }
    }
}

//
//  ext State.swift
//  SwiftOSC
//
//  Created by Felix on 26.03.24.
//  Copyright © 2024 Devin Roth Music. All rights reserved.
//

import Foundation
import Network

extension NWConnection.State {
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
            return "Failed (\(error.localizedDescription))"
        @unknown default:
            return "Unknown"
        }
    }
}

extension NWListener.State {
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
                // FIXME: Error description is very long
                return POSIXError(errorNumber).localizedDescription
            } else {
            return String(describing: error)
            }
//            return "Failed (\(error.localizedDescription))"
        @unknown default:
            return "Unknown"
        }
    }
}

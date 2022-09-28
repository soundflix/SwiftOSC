//
//  Log.swift
//  SwiftOSC
//
//  Created by Felix on 28.09.22.
//  Copyright © 2022 Devin Roth Music. All rights reserved.
//

import OSLog

public let SwiftOSCLog: OSLog = Logging.logger(category: "SwiftOSC")

/// Builder of OSLog values for categorization / classification of log statements.
internal struct Logging {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "<notSpecified>"
    /**
     Create a new logger for a subsystem
     - parameter subsystem: usually the app's bundle indentifier
     - parameter category: the category to log under
     - returns: OSLog instance to use for subsystem logging
     */
    public static func logger(subsystem: String = subsystem, category: String) -> OSLog { OSLog(subsystem: subsystem, category: category) }
}

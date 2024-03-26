//
//  OSCTesterApp.swift
//  OSCTester
//
//  Created by Felix on 25.03.24.
//

import SwiftUI
import SwiftOSC

@main
struct OSCTesterApp: App {
    @StateObject var server: OSCServer = OSCServer(port: 9004)
    @StateObject var client: OSCClient = OSCClient(host: "127.0.0.1", port: 7004)
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(server)
                .environmentObject(client)
        }
    }
}

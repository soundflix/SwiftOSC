//
//  ContentView.swift
//  OSCTester
//
//  Created by Felix on 25.03.24.
//

import SwiftUI
import SwiftOSC
import Network
import AppKit

struct ContentView: View {
    @EnvironmentObject var server: OSCServer
    @StateObject var receiver = OSCReceiver()
    @EnvironmentObject var client: OSCClient
    
    // FIXME: store as UInt16
    @State private var serverPort = "9004"
    @State private var bonjourName: String? = nil
    @State private var clientPort = "7004"
    
    func newServer() {
        if let port = NWEndpoint.Port(rawValue: UInt16(serverPort) ?? 0) { // }, port != server.port {
            server.restart(port: port, bonjourName: bonjourName)
        } else {
            NSSound.beep()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Button("Send") {
//                client.send(OSCMessage(OSCAddressPattern("/1/mute/1/1")!, [Float(1)]))
//                client.sendFloat(address: "/busOutput", AFloat: 1.0)
//                client.sendFloat(address: "/1", AFloat: 1.0)
                client.sendFloat(address: "/1/mute/1/3", AFloat: 1.0)
            }
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.gray)
                Image(systemName: "link")
                    .foregroundColor(client.connectionState == .ready ? .green : .red)
                    .onTapGesture {
                        client.restart()
                    }
                TextField("Port:", text: $clientPort)
                    .onSubmit {
                        client.restart()
                    }
                    .frame(width: 45)
                Text(" ----- ")
                    .foregroundColor(.secondary)
                    .frame(idealWidth: 200)
                Divider()
                Text("\(client.connectionState.description)")
                    .frame(idealWidth: 200)
            }
            
            Divider()
            Button("Stop server") {
                server.stop()
                receiver.text = ""
            }
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(server.listenerState == .ready ? .green : .red)
                    .onTapGesture {
                        newServer()
                    }
                Image(systemName: "link")
                    .foregroundColor(server.connectionState == .ready ? .green : .red)
                TextField("Port:", text: $serverPort)
                    .onSubmit {
                        newServer()
                    }
                    .frame(width: 45)
                Text("\(server.listenerState.description)")
                    .frame(idealWidth: 200)
                Divider()
                Text("\(server.connectionState.description)")
                    .frame(idealWidth: 200)
            }
            Text("\(receiver.text)")
        }
        .padding()
        .fixedSize()
        .onAppear {
            server.delegate = receiver
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let server: OSCServer = OSCServer(port: 9004)
        ContentView()
            .environmentObject(server)
    }
}

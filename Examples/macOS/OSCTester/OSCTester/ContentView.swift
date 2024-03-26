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
            Text("CLIENT")
                .foregroundColor(.secondary)
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
                    .foregroundColor(client.connectionState != .ready ? .red : .secondary)
                    .frame(idealWidth: 200)
                Divider()
                Text("\(String(describing: client.sendError))")
                    .frame(idealWidth: 200)
                    .foregroundColor(client.sendError != nil ? .red : .secondary)
            }
            .frame(height: 25)
            OSCSenderField(client: client)
            
            Divider()
            Text("SERVER")
                .foregroundColor(.secondary)
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
                    .foregroundColor(server.listenerState != .ready ? .red : .secondary)
                    .frame(idealWidth: 200)
                Divider()
                Text("\(server.connectionState.description)")
                    .foregroundColor(server.connectionState != .ready ? .red : .secondary)
                    .frame(idealWidth: 200)
            }
            .frame(height: 25)
            HStack {
                Button("Restart") {
                    server.stop()
                    receiver.text = ""
                }
                Button("Stop") {
                    server.stop()
                    receiver.text = ""
                }
            }
            HStack {
                Text("rcv:")
                Text("\(receiver.text)")
                    .padding(5)
                    .background(.gray.opacity(0.15))
                    .cornerRadius(5)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            server.delegate = receiver
            client.sendFloat(address: "/1", AFloat: 1.0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let server = OSCServer(port: 9004)
        let client = OSCClient(host: "localhost", port: 7004)
        ContentView()
            .environmentObject(server)
            .environmentObject(client)
    }
}

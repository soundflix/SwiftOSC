//
//  ContentView.swift
//  OSCTester
//
//  Created by Felix on 25.03.24.
//

import SwiftUI
import SwiftOSC
import Network

struct ContentView: View {
    @EnvironmentObject var client: OSCClient
    @EnvironmentObject var server: OSCServer
    @StateObject private var receiver = OSCReceiver(for: .page1)
    
    @State private var clientPort: NWEndpoint.Port = 7004
    @State private var serverPort: NWEndpoint.Port = 9004
    @State private var bonjourName: String? = nil
        
    @State private var newMessageHighlight = false
    
    func newServer() {
        server.restart(port: serverPort, bonjourName: bonjourName)
    }
    
    func newClient() {
        client.restart(port: clientPort)
        client.push(.page1)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("CLIENT (Send)   ")
                    .foregroundColor(.secondary)
                Button("Restart") {
                    client.restart()
                }
//                Text("\(client.connection.debugDescription)")
//                    .foregroundColor(.secondary)
            }
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.gray)
                Image(systemName: "link")
                    .foregroundColor(client.connectionState == .ready ? .green : .red)
                NWPortField(port: $clientPort)
                    .onChange(of: clientPort) { _ in
                        newClient()
                    }
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
                    .foregroundColor(.red)
            }
            .frame(height: 25)
            OSCSendField(client: client, floatWidth: 40)
                .frame(width: 300)
            
            Divider()
            HStack {
                Text("SERVER (Receive)")
                    .foregroundColor(.secondary)
                Button("Restart") {
                    newServer()
                    receiver.reset()
                }
//                Text("\(server.connection.debugDescription)")
//                    .foregroundColor(.secondary)
            }
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(server.listenerState == .ready ? .green : .red)
                Image(systemName: "link")
                    .foregroundColor(server.connectionState == .ready ? .green : .red)
                NWPortField(port: $serverPort)
                    .onChange(of: serverPort) { _ in
                        newServer()
                        receiver.reset()
                    }
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
                Text("Rcv: \(receiver.messageCount)")
                    .frame(width: 60, alignment: .leading)
                    .foregroundColor(receiver.isReceiving ? .green : .red)
                Text("\(receiver.text)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(newMessageHighlight ? .brown : .primary)
                    .animation(.spring(), value: newMessageHighlight)
                    .onChange(of: receiver.messageCount) { _ in
                        newMessageHighlight = true
                        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) {_ in
                            self.newMessageHighlight = false
                        }
                    }
                    .padding(5)
                    .background(.gray.opacity(0.15))
                    .cornerRadius(5)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            server.delegate = receiver
            client.push(.page1)
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

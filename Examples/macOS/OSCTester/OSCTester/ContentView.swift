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
    @EnvironmentObject var server: OSCServer
    @StateObject var receiver = OSCReceiver()
    @EnvironmentObject var client: OSCClient
    
    // FIXME: store as UInt16
    @State private var serverPort = "9004"
    @State private var bonjourName: String? = nil
    @State private var clientPort = "7004"
    
    @State private var newTextArrived = false
    
    func newServer() {
        if let portInt = UInt16(serverPort), let port = NWEndpoint.Port(rawValue: portInt) {
            server.restart(port: port, bonjourName: bonjourName)
        } else {
            NSSound.beep()
        }
    }
    
    func newClient() {
        if let portInt = UInt16(clientPort), let port = NWEndpoint.Port(rawValue: portInt) {
            client.restart(port: port)
            client.push()
        } else {
            NSSound.beep()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("CLIENT")
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
                TextField("Port:", text: $clientPort)
                    .onSubmit {
                        newClient()
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
            HStack {
                Text("SERVER")
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
                    .onTapGesture {
                        newServer()
                        receiver.reset()
                    }
                Image(systemName: "link")
                    .foregroundColor(server.connectionState == .ready ? .green : .red)
                TextField("Port:", text: $serverPort)
                    .onSubmit {
                        newServer()
                        receiver.reset()
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
                Text("Rcv: \(receiver.messageCount)")
                    .frame(width: 60, alignment: .leading)
                Text("\(receiver.text)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(newTextArrived ? .brown : .primary)
                    .animation(.spring(), value: newTextArrived)
                    .onChange(of: receiver.messageCount) { _ in
                        newTextArrived = true
                        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) {_ in
                            self.newTextArrived = false
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
            client.push()
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

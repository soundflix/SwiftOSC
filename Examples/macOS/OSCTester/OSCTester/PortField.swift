//
//  PortField.swift
//  OSCTester
//
//  Created by Felix on 27.03.24.
//

import SwiftUI
import Network

/// Custom **TextField for port numbers** with validation.
/// Invalid entry will be will replaced with previous value.
/// Can use Escape key (ExitAction) to unfocus without change.
///
/// The port numbers in the range from 0 to 1023 (0 to 210 − 1) are the **well-known ports or system ports**.
///
/// The range of port numbers from 1024 to 49151 (210 to 215 + 214 − 1) are the **registered ports**.
///
/// The range 49152–65535 (215 + 214 to 216 − 1), 16 384 ports, contains **dynamic or private ports** that cannot be registered with IANA.
/// This range is used for private or customized services, for temporary purposes, and for automatic allocation of ephemeral ports.
///
/// See: [List of TCP and UDP port numbers]( https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers)
struct PortField: View {
    
    @Binding var port: NWEndpoint.Port
    @State private var oldPort: NWEndpoint.Port = NWEndpoint.Port(integerLiteral: 0)
    @State private var newPort: NWEndpoint.Port = NWEndpoint.Port(integerLiteral: 0)
    @FocusState private var portIsFocused: Bool

    var body: some View {
        
        let validatePort = Binding(
            get: {
                String(self.newPort.rawValue)
            },
            set: {
                self.newPort = NWEndpoint.Port(integerLiteral: UInt16($0) ?? self.port.rawValue)
            })
        
        TextField("port", text: validatePort)
            .multilineTextAlignment(.trailing)
            .frame(width: 50) /// fits for up to '65535'
            .onAppear {
                self.oldPort = $port.wrappedValue
                self.newPort = $port.wrappedValue
                print("PortField onAppear: old: \(oldPort) new: \(newPort)")
            }
            .focused($portIsFocused)
            .onSubmit {
                portIsFocused = false
                print("PortField submitted \(port.rawValue)")
                port = newPort
                oldPort = newPort
            }
            .onExitCommand {
                portIsFocused = false
                port = oldPort
                newPort = oldPort
            }
    }
}

struct PortField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PortField(port: .constant(NWEndpoint.Port(integerLiteral: UInt16(7004))))
            
            PortField(port: .constant(NWEndpoint.Port(integerLiteral: UInt16(0))))
            
            PortField(port: .constant(NWEndpoint.Port(integerLiteral: UInt16(Int(65535)))))
        }
    }
}

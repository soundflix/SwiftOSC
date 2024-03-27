//
//  PortField.swift
//  OSCTester
//
//  Created by Felix on 27.03.24.
//

import SwiftUI
import Network

struct PortField: View {
    
    @Binding var port: NWEndpoint.Port
    @State private var oldPort: NWEndpoint.Port = 0
    @FocusState private var portIsFocused: Bool
    
    init(port: Binding<NWEndpoint.Port>) {
        self._port = port
        self.oldPort = port.wrappedValue
    }
    
    var body: some View {
        
        let validatePort = Binding(
            get: { String(self.port.rawValue) },
            // FIXME: truncates silently. Warn/signal when invalid?
            set: { self.port = NWEndpoint.Port(integerLiteral: UInt16($0) ?? self.port.rawValue) })
        
        TextField("port", text: validatePort)
            .multilineTextAlignment(.trailing)
            .frame(width: 45)
            .focused($portIsFocused)
            .onSubmit {
                portIsFocused = false
                print("PortField submitted \(port.rawValue)")
                oldPort = port
            }
            .onExitCommand {
                // FIXME: set old value here
                portIsFocused = false
                port = oldPort
            }
        
            .onChange(of: port) { newValue in
                print("PortField onChange: \(newValue.rawValue), oldValue: \(oldPort.rawValue)")
            }
        
    }
}

struct PortField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PortField(port: .constant(NWEndpoint.Port(integerLiteral: UInt16(7004))))
            
            PortField(port: .constant(NWEndpoint.Port(integerLiteral: UInt16(0))))
            
//            PortField(port: .constant(UInt16(111111111111111111111111111111)))
            // Integer literal '111111111111111111111111111111' overflows when stored into 'UInt16'
            
//            PortField(port: .constant(Int(7004)))
            // Cannot convert value of type 'Int' to expected argument type 'UInt16'
            
            PortField(port: .constant(NWEndpoint.Port(integerLiteral: UInt16(Int(7004)))))
        }
    }
}

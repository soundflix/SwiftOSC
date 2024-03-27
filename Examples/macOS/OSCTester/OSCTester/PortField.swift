//
//  PortField.swift
//  OSCTester
//
//  Created by Felix on 27.03.24.
//

import SwiftUI

struct PortField: View {
    
    @Binding var port: UInt16
    
    var body: some View {
        let convertPort = Binding(
            get: { String(self.port) },
            set: { self.port = UInt16($0) ?? self.port })

        // FIXME: alignment: .trailing in TextField?
        TextField("Port:", text: convertPort)
//            .onSubmit {
//                newClient()
//            }
            .frame(width: 45)
    }
}

struct PortField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PortField(port: .constant(UInt16(7004)))
            
            PortField(port: .constant(UInt16(0)))
            
//            PortField(port: .constant(UInt16(111111111111111111111111111111)))
            // Integer literal '111111111111111111111111111111' overflows when stored into 'UInt16'
            
//            PortField(port: .constant(Int(7004)))
            // Cannot convert value of type 'Int' to expected argument type 'UInt16'
            
            PortField(port: .constant(UInt16(Int(7004))))

        }
    }
}

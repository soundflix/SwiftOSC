//
//  OSCSender.swift
//  OSCTester
//
//  Created by Felix on 26.03.24.
//

import SwiftUI
import SwiftOSC

struct OSCSendField: View {
    let client: OSCClient
    let value: CGFloat = 60
    @State private var address = "/1/mute/1/3"
    // TODO: extend to any OSCType?
    @State private var float: Float = 1.0
    
    private func send() {
        client.sendFloat(address: address, AFloat: float)
    }
    var body: some View {
        HStack {
            Button("Send") {
                client.sendFloat(address: address, AFloat: float)
            }
            .keyboardShortcut("s")
            TextField("address:", text: $address)
                .onSubmit {
                    send()
                }
            TextField("float", value: $float, format: .number)
                .onSubmit {
                    send()
                }
                .frame(width: value)
        }
    }
}

struct OSCSender_Previews: PreviewProvider {
    static var previews: some View {
        OSCSendField(client: OSCClient(host: "localhost", port: 9004))
    }
}

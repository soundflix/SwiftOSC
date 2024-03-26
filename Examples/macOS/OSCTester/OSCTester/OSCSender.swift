//
//  OSCSender.swift
//  OSCTester
//
//  Created by Felix on 26.03.24.
//

import SwiftUI
import SwiftOSC

struct OSCSender: View {
    let client: OSCClient
    @State private var address = "/1/mute/1/3"
    @State private var float: Float = 1.0
    
    var body: some View {
        HStack {
            Button("Send") {
                client.sendFloat(address: address, AFloat: float)
            }
            TextField("address:", text: $address)
            TextField("float", value: $float, format: .number)
        }
    }
}

struct OSCSender_Previews: PreviewProvider {
    static var previews: some View {
        OSCSender(client: OSCClient(host: "localhost", port: 9004))
    }
}

# SwiftOSC v2.1

## New features:
- Alternative delegate method `didReceive(_ message: OSCMessage, port: NWEndpoint.Port)`

# SwiftOSC v2.0

[![License](https://img.shields.io/cocoapods/l/SwiftOSC.svg?style=flat)](https://github.com/devinroth/SwiftOSC/blob/master/LICENSE)
<img src="https://img.shields.io/badge/in-swift5.3-orange.svg">

SwiftOSC is a Swift Open Sound Control (OSC) 1.1 client and server framework.


## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

```swift
dependencies: [
    .package(url: "https://github.com/soundflix/SwiftOSC.git", from: "2.0")
]
```

Alternatively, you can add the package [directly via Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

OR install locally:

### Step 1

Clone or download repository from Github.

### Step 2

Open SwiftOSC.xcworkspace and build SwiftOSC frameworks.

### Step 3

Embed SwiftOSC into project.



## Quick Start
### OSC Server
#### Step 1
Import SwiftOSC framework into your project
```swift
import SwiftOSC
```
#### Step 2
Create Server
```swift
var server = OSCServer(port: 8080)
```

#### Step 3
Setup server delegate to handle incoming OSC Data
```swift
class OSCHandler: OSCServerDelegate {

    func didReceive(_ message: OSCMessage){
        if let integer = message.arguments[0] as? Int {
            print("Received int \(integer)")
        } else {
            print(message)
        }
    }
}
server.delegate = OSCHandler()
```
### alternative: Steps 2 & 3 combined:
Set delegate in init:
```swift
var server = OSCServer(port: 8080, delegate: OSCHandler())
```

### OSC Client
#### Step 1
Import SwiftOSC framework into your project
```swift
import SwiftOSC
```
#### Step 2
Create OSCClient
```swift
var client = OSCClient(host: "localhost", port: 8080)
```
#### Step 3
Create an OSCAddressPattern and  OSCMessage
```swift

var message = OSCMessage(
    OSCAddressPattern("/")!,
    100,
    5.0,
    "Hello World",
    true,
    false,
    nil,
    OSCBlob(),                  // aka Data()
    OSCImpulse(),
    OSCTimetag(1)               // aka UInt64()
)
```
#### Step 4
Send message
```swift
client.send(message)
```
## Known Issues


## About

[Devin Roth](http://devinrothmusic.com) is a composer and programmer. When not composing, teaching, or being a dad, Devin attempts to make his life more efficient by writing programs.

For additional information on Open Sound Control visit http://opensoundcontrol.org/.

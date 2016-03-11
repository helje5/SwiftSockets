SwiftSockets
============

A simple GCD based socket library for Swift.

SwiftSockets is kind of a demo on how to integrate Swift with raw C APIs. More
for stealing Swift coding ideas than for actually using the code in a real
world project. In most real world Swift apps you have access to Cocoa, use it.

####Importing SwiftSockets

**NOTE**: Updated for Swift swift-DEVELOPMENT-SNAPSHOT-2016-03-01-a-ubuntu15.10.
This is the feature branch for the Linux port of SwiftSockets. Make sure you
have GCD installed.

**NOTE**: This is still incomplete. You can go into the SwiftSockets subdir
and call `make`. It should build successfully.

The SPM  version of this project  just carries the library.  While ARIEchoServer
and  ARIFetch are  still  in the  directory,  they don't  build  via SPM  (yet).
However,    there     is    a     great    new    standalone     Echo    server:
[SwiftyEchoDaemon](http://www.alwaysrightinstitute.com/SwiftyEchoDaemon/)  which
you can grab as an example on how to use SwiftSockets in SPM.

To use SwiftSockets in your SPM tool, just add it as a dependency in your
`Package.swift` file, like so:

    import PackageDescription
    
    let package = Package(
      name:         "SwiftyEcho",
      targets:      [],
      dependencies: [
        .Package(url: "https://github.com/AlwaysRightInstitute/SwiftSockets.git",
                 majorVersion: 0, minor: 1
        )
      ]
    )


####SwiftSockets

A framework containing the socket classes and relevant extensions. It takes a
bit of inspiration from the [SOPE](http://sope.opengroupware.org) NGStreams
library.

Server Sample:
```swift
let socket = PassiveSocket<sockaddr_in>(address: sockaddr_in(port: 4242))!
  .listen(dispatch_get_global_queue(0, 0), backlog: 5) {
    print("Wait, someone is attempting to talk to me!")
    $0.close()
    print("All good, go ahead!")
  }
```

Client Sample:
```swift
let socket = ActiveSocket<sockaddr_in>()!
  .onRead { sock, _ in
    let (count, block, errno) = sock.read() // $0 for sock doesn't work anymore?
    guard count > 0 else {
      print("EOF, or great error handling \(errno).")
      return
    }
    print("Answer to ring,ring is: \(count) bytes: \(block)")
  }
  .connect("127.0.0.1:80") { socket in
    socket.write("Ring, ring!\r\n")
  }
```

####SwiftyEchoDaemon

[The **bezt** Echo daemon ever written in Swift]((http://www.alwaysrightinstitute.com/SwiftyEchoDaemon/))
- SPM version.

This is a demo on how to use the
[SwiftSockets Swift Package Manager version](https://github.com/AlwaysRightInstitute/SwiftSockets/tree/feature/linux)
on Linux or OSX.

Great echo server. Compile it via `make`, run it via `make run`, then
connect to it in the Terminal.app via ```telnet 1337```.

![](http://i.imgur.com/mzXANTC.png)

###Goals

- [x] Max line length: 80 characters
- [ ] Great error handling
  - [x] PS style great error handling
  - [x] print() error handling
  - [ ] Swift 2 try/throw/catch
    - [ ] Real error handling
- [x] Twisted (no blocking reads or writes)
  - [x] Async reads and writes
    - [x] Never block on reads
    - [x] Never block on listen
  - [ ] Async connect()
- [ ] Support all types of Unix sockets & addresses
  - [x] IPv4
  - [ ] IPv6 (I guess this should work too)
  - [ ] Unix domain sockets
  - [ ] Datagram sockets
- [x] No NS'ism
- [ ] Use as many language features Swift provides
  - [x] Generics
    - [x] Generic function
    - [x] typealias
  - [x] Closures
    - [x] weak self
    - [x] trailing closures
    - [x] implicit parameters
  - [ ] Unowned
  - [x] Extensions on structs
  - [x] Extensions to organize classes
  - [x] Protocols on structs
  - [ ] Swift 2 protocol extensions
  - [x] Tuples, with labels
  - [x] Trailing closures
  - [ ] @Lazy
  - [x] Pure Swift weak delegates via @class
  - [x] Optionals
  - [x] Convenience initializers
  - [x] Failable initializers
  - [x] Class variables on structs
  - [x] CConstPointer, CConstVoidPointer
    - [x] withCString {}
  - [x] UnsafePointer
  - [x] sizeof()
  - [x] Standard Protocols
    - [x] Printable
    - [x] BooleanType (aka LogicValue)
    - [x] OutputStreamType
    - [x] Equatable
      - [ ] Equatable on Enums with Associated Values
    - [x] Hashable
    - [x] SequenceType (GeneratorOf<T>)
    - [x] Literal Convertibles
      - [x] StringLiteralConvertible
      - [ ] IntegerLiteralConvertible
  - [x] Left shift AND right shift
  - [ ] Enums on steroids
  - [ ] Dynamic type system, reflection
  - [x] Operator overloading
  - [ ] UCS-4 identifiers (🐔🐔🐔)
  - [ ] ~~RTF source code with images and code sections in different fonts~~
  - [ ] Nested classes/types
  - [ ] Patterns
    - [x] Use wildcard pattern to ignore value
  - [x] Literal Convertibles
  - [ ] @autoclosure
  - [ ] unsafeBitCast (was reinterpretCast)
  - [x] final
  - [x] Nil coalescing operator
  - [ ] dynamic
  - [ ] Swift 2
    - [ ] availability
    - [x] guard
    - [x] defer
    - [ ] C function pointers
    - [x] debugPrint
    - [ ] lowercaseString
- [ ] Swift Package Manager
- [ ] Linux support

###Why?!

This is an experiment to get acquainted with Swift. To check whether something
real can be implemented in 'pure' Swift. Meaning, without using any Objective-C
Cocoa classes (no NS'ism).
Or in other words: Can you use Swift without writing all the 'real' code in
wrapped Objective-C? :-)

###Contact

[@helje5](http://twitter.com/helje5) | helge@alwaysrightinstitute.com

![](http://www.alwaysrightinstitute.com/images/ARI-symbol-logo.png)

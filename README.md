SwiftSockets
============

A simple GCD based socket library for Swift.

SwiftSockets is kind of a demo on how to integrate Swift with raw C APIs. More
for stealing Swift coding ideas than for actually using the code in a real
world project. In most real world Swift apps you have access to Cocoa, use it.

It also comes with a great Echo daemon as a demo, it's always there if you need
a chat.

**Note**: This is my first [Swift](https://developer.apple.com/swift/) project.
Any suggestions on how to improve the code are welcome. I expect lots and lots
:-)

###Targets

The project includes three targets:
- SwiftSockets
- ARIEchoServer
- ARIFetch

Updated for Swift 0.2.2 (aka Xcode 7.3).

*Note for Linux users*:
This compiles with the 2016-03-01-a snapshot via Swift Package Manager
as well as with the Swift 2.2 release using the embedded makefiles.
Make sure you 
[install Grand Central Dispatch](http://www.alwaysrightinstitute.com/swift-on-linux-in-vbox-on-osx/)
into your Swift installation.
On Linux the included ARIEchoServer/ARIFetch apps do not build, but this one
does and is embedded:
[SwiftyEchoDaemon](http://www.alwaysrightinstitute.com/SwiftyEchoDaemon/).

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

####Using SwiftSockets with Swift Package Manager

To use SwiftSockets in your SPM project, just add it as a dependency in your
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


####ARIEchoServer / SwiftyEchoDaemon

There is the ARIEchoServer for Xcode and SwiftEchoDaemon for Package Manager
installs. Your choize, both are equally awezome.

ARIEchoServer is a Cocoa app. Compile it, run it, then
connect to it in the Terminal.app via ```telnet 1337```.

![](http://i.imgur.com/874ovtE.png)

[The **bezt** Echo daemon ever written in Swift](http://www.alwaysrightinstitute.com/SwiftyEchoDaemon/) - SPM version.
This is a demo on how to write a SwiftSockets server using the
Swift Package Manager, on Linux or OSX.
It also works w/o SPM if SwiftSockets has been built
via Makefiles.

Great echo server. Compile it via `make`, run it via `make run`, then
connect to it in the Terminal.app via ```telnet 1337```.

![](http://i.imgur.com/mzXANTC.png)

####ARIFetch

Connects a socket to some end point, sends an HTTP/1.0 GET request with some
awesome headers, then shows the results the server sends. Cocoa app.

Why HTTP/1.0? Avoids redirects on www.apple.com :-)

![](http://i.imgur.com/nRhADxg.png)


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
    - [x] BooleanType (aka LogicValue[1.x] aka Boolean[3.x])
    - [x] OutputStreamType / Swift 3 OutputStream
    - [x] Equatable
      - [ ] Equatable on Enums with Associated Values
    - [x] Hashable
    - [x] SequenceType (GeneratorOf<T>)
      - [x] Swift 3 Sequence (Iterator<T>)
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
  - [x] #if os(Linux)
  - [ ] #if swift(>=2.2)
- [x] Swift Package Manager
  - [x] GNUmakefile support
  - [ ] #if SWIFT_PACKAGE
- [x] Linux support
- [x] Swift 3 2016-03-16

###Why?!

This is an experiment to get acquainted with Swift. To check whether something
real can be implemented in 'pure' Swift. Meaning, without using any Objective-C
Cocoa classes (no NS'ism).
Or in other words: Can you use Swift without writing all the 'real' code in
wrapped Objective-C? :-)

###Contact

[@helje5](http://twitter.com/helje5) | helge@alwaysrightinstitute.com

![](http://www.alwaysrightinstitute.com/images/ARI-symbol-logo.png)

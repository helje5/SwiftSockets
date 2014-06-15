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
- ARISockets
- ARIEchoServer
- ARIFetch

I suggest you start out looking at the ARIEchoServer.

####ARISockets

A framework containing the socket classes and relevant extensions. It takes a bit of inspiration from the [SOPE](http://sope.opengroupware.org) NGStreams library.

Server Sample:
```swift
let socket = PassiveSocket(address: sockaddr_in(port: 4242))
socket.listen(dispatch_get_global_queue(0, 0), backlog: 5) {
  clientSocket in
  println("Wait, someone is attempting to talk to me!")
  clientSocket.close()
  println("All good, go ahead!")
}
```

Client Sample:
```swift
let socket = ActiveSocket()
socket.onRead = {
  let (count, block) = socket.read()
  if count < 1 {
    println("EOF, or great error handling.")
    return
  }
  println("Answer to ring,ring is: \(count) bytes: \(block)")
}
socket.connect(sockaddr_in(port:80, address:"127.0.0.1"))
socket.write("Ring, ring!\r\n")
```

####ARIEchoServer

Great echo server. This is actually a Cocoa app. Compile it, run it, then
connect to it in the Terminal.app via ```telnet 8042```.

![](http://i.imgur.com/874ovtE.png)

####ARIFetch

Connects a socket to some end point, sends an HTTP/1.0 GET request with some
awesome headers, then shows the results the server sends. Cocoa app.

Why HTTP/1.0? Avoids redirects on www.apple.com :-)

![](http://i.imgur.com/nRhADxg.png)


###Goals

- [x] Max line length: 80 characters
- [ ] Great error handling
  - [x] PS style great error handling
  - [x] println() error handling
  - [ ] Real error handling
- [x] Twisted (no blocking reads or writes)
  - [x] Async reads and writes
    - [ ] Never block :-)
  - [ ] Async connect()
- [ ] Support all types of Unix sockets & addresses
  - [x] IPv4
  - [ ] IPv6 (I guess this should work too)
  - [ ] Unix domain sockets
  - [ ] Datagram sockets
- [x] No NS'ism
- [ ] Use as many language features Swift provides
  - [ ] Generics (swiftc segfaults)
  - [x] Closures
    - [x] weak self
  - [ ] Unowned
  - [x] Extensions on structs
  - [ ] Extensions to organize classes (swiftc segfaults)
  - [x] Protocols on structs
  - [x] Tuples
  - [x] Trailing closures
  - [ ] @Lazy
  - [x] Pure Swift weak delegates via @class
  - [x] Optionals
  - [x] Convenience initializers
  - [x] Class variables on structs
  - [x] CConstPointer, CConstVoidPointer
    - [x] withCString {}
  - [x] sizeof()
  - [x] Standard Protocols
    - [x] Printable
    - [x] LogicValue
    - [x] OutputStream
  - [x] Left shift AND right shift
  - [ ] Enums on steroids
  - [ ] Dynamic type system, reflection
  - [x] Operator overloading
  - [ ] UCS-4 identifiers
  - [ ] ~~RTF source code with images and code sections in different fonts~~

###Why?!

This is an experiment to get acquainted with Swift. To check whether something
real can be implemented in 'pure' Swift. Meaning, without using any Objective-C
Cocoa classes (no NS'ism).
Or in other words: Can you use Swift without writing all the 'real' code in
wrapped Objective-C? :-)

###Contact

[@helje5](http://twitter.com/helje5) | helge@alwaysrightinstitute.com

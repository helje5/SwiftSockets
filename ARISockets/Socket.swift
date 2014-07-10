//
//  ARISocket.swift
//  TestSwiftyCocoa
//
//  Created by Helge Heß on 6/9/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

import Darwin
import Dispatch

/**
 * Simple Socket classes for Swift.
 *
 * PassiveSockets are 'listening' sockets, ActiveSockets are open connections.
 */
class Socket<T: SocketAddress> {
  
  var fd           : Int32?             = nil
  var boundAddress : T?                 = nil
  var closeCB      : ((Int32) -> Void)? = nil
  var closedFD     : Int32?             = nil // for delayed callback
  var isValid      : Bool { return fd != nil }
  var isBound      : Bool {
    // fails: return boundAddress != nil
    if let a = boundAddress { return true } else { return false }
  }
  
  
  /* initializer / deinitializer */
  
  init(fd: Int32?) {
    self.fd = fd
  }
  deinit {
    close() // TBD: is this OK/safe?
  }
  
  convenience init(type: Int32 = SOCK_STREAM) {
    let lfd = socket(T.domain, type, 0)
    var fd:  Int32?
    if lfd != -1 {
      fd = lfd
    }
    else {
      // This is lame. Would like to 'return nil' ...
      // TBD: How to do proper error handling in Swift?
      println("Could not create socket.")
    }
    
    self.init(fd: fd)
  }
  
  
  /* explicitly close the socket */
  
  let debugClose = false
  
  func close() {
    if fd {
      closedFD = fd
      if debugClose { println("Closing socket \(closedFD) for good ...") }
      Darwin.close(fd!)
      fd       = nil
      
      if let cb = closeCB {
        // can be used to unregister socket etc when the socket is really closed
        if debugClose { println("  let closeCB \(closedFD) know ...") }
        cb(closedFD!)
        closeCB = nil // break potential cycles
      }
      if debugClose { println("done closing \(closedFD)") }
    }
    else if debugClose {
      println("socket \(closedFD) already closed.")
    }
    boundAddress = nil
  }
  
  func onClose(cb: ((Int32) -> Void)?) -> Self {
    if let fd = closedFD { // socket got closed before event-handler attached
      if let lcb = cb {
        lcb(fd)
      }
      else {
        closeCB = nil
      }
    }
    else {
      closeCB = cb
    }
    return self
  }
  
  
  /* bind the socket. */
  
  func bind(address: T) -> Bool {
    if !isValid {
      return false
    }
    if isBound {
      println("Socket is already bound!")
      return false
    }
    
    // Note: must be 'var' for ptr stuff, can't use let
    var addr = address
    
    let rc = withUnsafePointer(&addr) {
      (ptr: UnsafePointer<T>) -> Int32 in
      let bptr = ConstUnsafePointer<sockaddr>(ptr) // cast
      return Darwin.bind(self.fd!, bptr, socklen_t(addr.len))
    }
    
    if rc == 0 {
      // Generics TBD: cannot check for isWildcardPort, always grab the name
      boundAddress = getsockname()
      /* if it was a wildcard port bind, get the address */
      // boundAddress = addr.isWildcardPort ? getsockname() : addr
    }
    
    return rc == 0 ? true : false
  }
  
  func getsockname() -> T? {
    if !isValid {
      return nil
    }
    
    // FIXME: tried to encapsulate this in a sockaddrbuf which does all the
    //        ptr handling, but it ain't work (autoreleasepool issue?)
    var baddr    = T()
    var baddrlen = socklen_t(baddr.len)
    
    // Note: we are not interested in the length here, would be relevant
    //       for AF_UNIX sockets
    let rc = withUnsafePointer(&baddr) {
      (ptr: UnsafePointer<T>) -> Int32 in
      let bptr = UnsafePointer<sockaddr>(ptr) // cast
      return withUnsafePointer(&baddrlen) {
        (buflenptr: UnsafePointer<socklen_t>) -> Int32 in
        return Darwin.getsockname(self.fd!, bptr, buflenptr)
      }
    }
    
    if (rc != 0) {
      println("Could not get sockname? \(rc)")
      return nil
    }
    
    // println("PORT: \(baddr.sin_port)")
    return baddr
  }
  
  
  /* description */
  
  // must live in the main-class as 'declarations in extensions cannot be
  // overridden yet'
  func descriptionAttributes() -> String {
    var s = fd ? " fd=\(fd!)" : (closedFD ? " closed[\(closedFD)]" :" not-open")
    if boundAddress {
      s += " \(boundAddress!)"
    }
    return s
  }
  
}


extension Socket { // Socket Flags
  
  var flags : Int32? {
    get {
      let rc = ari_fcntlVi(fd!, F_GETFL, 0)
      return rc >= 0 ? rc : nil
    }
    set {
      let rc = ari_fcntlVi(fd!, F_SETFL, Int32(newValue!))
      if rc == -1 {
        println("Could not set new socket flags \(rc)")
      }
    }
  }
  
  var isNonBlocking : Bool {
    get {
      return (flags! & O_NONBLOCK) != 0 ? true : false
    }
    set {
      if newValue {
        flags = flags! | O_NONBLOCK
      }
      else {
        flags = flags! & ~O_NONBLOCK
      }
    }
  }
  
}


extension Socket { // Socket Options

  var reuseAddress: Bool {
    get { return getSocketOption(SO_REUSEADDR) }
    set { setSocketOption(SO_REUSEADDR, value: newValue) }
  }
  var isSigPipeDisabled: Bool {
    get { return getSocketOption(SO_NOSIGPIPE) }
    set { setSocketOption(SO_NOSIGPIPE, value: newValue) }
  }
  var keepAlive: Bool {
    get { return getSocketOption(SO_KEEPALIVE) }
    set { setSocketOption(SO_KEEPALIVE, value: newValue) }
  }
  var dontRoute: Bool {
    get { return getSocketOption(SO_DONTROUTE) }
    set { setSocketOption(SO_DONTROUTE, value: newValue) }
  }
  var socketDebug: Bool {
    get { return getSocketOption(SO_DEBUG) }
    set { setSocketOption(SO_DEBUG, value: newValue) }
  }
  
  var sendBufferSize: Int32 {
    get {
      let v: Int32? = getSocketOption(SO_SNDBUF)
      if v { return v! } else { return -42 }
    }
    set { setSocketOption(SO_SNDBUF, value: newValue) }
  }
  var receiveBufferSize: Int32 {
    get {
      let v: Int32? = getSocketOption(SO_RCVBUF)
      if v { return v! } else { return -42 }
    }
    set { setSocketOption(SO_RCVBUF, value: newValue) }
  }
  var socketError: Int32 {
    let v: Int32? = getSocketOption(SO_ERROR)
    if v { return v! } else { return -42 }
  }
  
  /* socket options (TBD: would we use subscripts for such?) */
  
  
  func setSocketOption(option: Int32, value: Int32) -> Bool {
    if !isValid {
      return false
    }
    
    var buf = value
    let rc  = setsockopt(fd!, SOL_SOCKET, option, &buf, socklen_t(sizeof(Int32)))
    
    if rc != 0 { // ps: Great Error Handling
      println("Could not set option \(option) on socket \(self)")
    }
    return rc == 0
  }
  
  // TBD: Can't overload optionals in a useful way?
  // func getSocketOption(option: Int32) -> Int32
  func getSocketOption(option: Int32) -> Int32? {
    if !isValid {
      return nil
    }
    
    var buf    = Int32(0)
    var buflen = socklen_t(sizeof(Int32))
    
    let rc = getsockopt(fd!, SOL_SOCKET, option, &buf, &buflen)
    if rc != 0 { // ps: Great Error Handling
      println("Could not get option \(option) from socket \(self)")
      return nil
    }
    return buf
  }
  
  func setSocketOption(option: Int32, value: Bool) -> Bool {
    return setSocketOption(option, value: value ? 1 : 0)
  }
  func getSocketOption(option: Int32) -> Bool {
    let v: Int32? = getSocketOption(option)
    return v ? (v! == 0 ? false : true) : false
  }
  
}


extension Socket { // poll()
  
  var isDataAvailable: Bool { return pollFlag(POLLRDNORM) }
  
  func pollFlag(flag: Int32) -> Bool {
    let rc: Int32? = poll(flag, timeout: 0)
    if let flags = rc {
      if (flags & flag) != 0 {
        return true
      }
    }
    return false
  }
  
  // Swift doesn't allow let's in here?!
  var pollEverythingMask : Int32 { return (
      POLLIN | POLLPRI | POLLOUT
    | POLLRDNORM | POLLWRNORM
    | POLLRDBAND | POLLWRBAND)
  }
  
  // Swift doesn't allow let's in here?!
  var debugPoll : Bool { return false }
  
  func poll(events: Int32, timeout: UInt? = 0) -> Int32? {
    // This is declared as Int32 because the POLLRDNORM and such are
    if !isValid {
      return nil
    }
    
    let ctimeout = timeout ? Int32(timeout!) : -1 /* wait forever */
    
    var fds = pollfd(fd: fd!, events: CShort(events), revents: 0)
    let rc  = Darwin.poll(&fds, 1, ctimeout)
    
    if rc < 0 {
      println("poll() returned an error")
      return nil
    }
    
    if debugPoll {
      var s = ""
      let mask = Int32(fds.revents)
      if 0 != (mask & POLLIN)     { s += " IN"  }
      if 0 != (mask & POLLPRI)    { s += " PRI" }
      if 0 != (mask & POLLOUT)    { s += " OUT" }
      if 0 != (mask & POLLRDNORM) { s += " RDNORM" }
      if 0 != (mask & POLLWRNORM) { s += " WRNORM" }
      if 0 != (mask & POLLRDBAND) { s += " RDBAND" }
      if 0 != (mask & POLLWRBAND) { s += " WRBAND" }
      println("Poll result \(rc) flags \(fds.revents)\(s)")
    }
    
    if rc == 0 {
      return nil
    }
    
    return Int32(fds.revents)
  }
  
}


extension Socket: Printable {
  
  var description: String {
    return "<Socket:" + descriptionAttributes() + ">"
  }
  
}


extension Socket: LogicValue {
  
  func getLogicValue() -> Bool {
    return isValid
  }
  
}
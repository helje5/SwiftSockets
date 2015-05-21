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
public class Socket<T: SocketAddress> {
  
  public var fd           : Int32?             = nil
  public var boundAddress : T?                 = nil
  public var isValid      : Bool { return fd != nil }
  public var isBound      : Bool {
    // fails: return boundAddress != nil
    if let a = boundAddress { return true } else { return false }
  }
  
  var closeCB  : ((Int32) -> Void)? = nil
  var closedFD : Int32?             = nil // for delayed callback
  
  
  /* initializer / deinitializer */
  
  public init(fd: Int32?) {
    self.fd = fd
  }
  deinit {
    close() // TBD: is this OK/safe?
  }
  
  public convenience init?(type: Int32 = SOCK_STREAM) {
    let lfd = socket(T.domain, type, 0)
    self.init(fd: lfd)
    if lfd == -1 { return nil }
  }
  
  
  /* explicitly close the socket */
  
  let debugClose = false
  
  public func close() {
    if fd != nil {
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
  
  public func onClose(cb: ((Int32) -> Void)?) -> Self {
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
  
  public func bind(address: T) -> Bool {
    if !isValid {
      return false
    }
    if isBound {
      println("Socket is already bound!")
      return false
    }
    let lfd = fd!
    
    // Note: must be 'var' for ptr stuff, can't use let
    var addr = address

    let rc = withUnsafePointer(&addr) { ptr -> Int32 in
      let bptr = UnsafePointer<sockaddr>(ptr) // cast
      return Darwin.bind(lfd, bptr, socklen_t(addr.len))
    }
    
    if rc == 0 {
      // Generics TBD: cannot check for isWildcardPort, always grab the name
      boundAddress = getsockname()
      /* if it was a wildcard port bind, get the address */
      // boundAddress = addr.isWildcardPort ? getsockname() : addr
    }
    
    return rc == 0 ? true : false
  }
  
  public func getsockname() -> T? {
    if !isValid {
      return nil
    }
    let lfd = fd!
    
    // FIXME: tried to encapsulate this in a sockaddrbuf which does all the
    //        ptr handling, but it ain't work (autoreleasepool issue?)
    var baddr    = T()
    var baddrlen = socklen_t(baddr.len)
    
    // Note: we are not interested in the length here, would be relevant
    //       for AF_UNIX sockets
    let rc = withUnsafeMutablePointer(&baddr) {
      ptr -> Int32 in
      let bptr = UnsafeMutablePointer<sockaddr>(ptr) // cast
      return Darwin.getsockname(lfd, bptr, &baddrlen)
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
    var s = fd != nil
      ? " fd=\(fd!)"
      : (closedFD != nil ? " closed[\(closedFD)]" :" not-open")
    if boundAddress != nil {
      s += " \(boundAddress!)"
    }
    return s
  }
  
}


extension Socket { // Socket Flags
  
  public var flags : Int32? {
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
  
  public var isNonBlocking : Bool {
    get {
      if let f = flags {
        return (f & O_NONBLOCK) != 0 ? true : false
      }
      else {
        println("ERROR: could not get non-blocking socket property!")
        return false
      }
    }
    set {
      if newValue {
        if let f = flags {
          flags = f | O_NONBLOCK
        }
        else {
          flags = O_NONBLOCK
        }
      }
      else {
        flags = flags! & ~O_NONBLOCK
      }
    }
  }
  
}


extension Socket { // Socket Options

  public var reuseAddress: Bool {
    get { return getSocketOption(SO_REUSEADDR) }
    set { setSocketOption(SO_REUSEADDR, value: newValue) }
  }
  public var isSigPipeDisabled: Bool {
    get { return getSocketOption(SO_NOSIGPIPE) }
    set { setSocketOption(SO_NOSIGPIPE, value: newValue) }
  }
  public var keepAlive: Bool {
    get { return getSocketOption(SO_KEEPALIVE) }
    set { setSocketOption(SO_KEEPALIVE, value: newValue) }
  }
  public var dontRoute: Bool {
    get { return getSocketOption(SO_DONTROUTE) }
    set { setSocketOption(SO_DONTROUTE, value: newValue) }
  }
  public var socketDebug: Bool {
    get { return getSocketOption(SO_DEBUG) }
    set { setSocketOption(SO_DEBUG, value: newValue) }
  }
  
  public var sendBufferSize: Int32 {
    get { return getSocketOption(SO_SNDBUF) ?? -42    }
    set { setSocketOption(SO_SNDBUF, value: newValue) }
  }
  public var receiveBufferSize: Int32 {
    get { return getSocketOption(SO_RCVBUF) ?? -42    }
    set { setSocketOption(SO_RCVBUF, value: newValue) }
  }
  public var socketError: Int32 {
    return getSocketOption(SO_ERROR) ?? -42
  }
  
  /* socket options (TBD: would we use subscripts for such?) */
  
  
  public func setSocketOption(option: Int32, value: Int32) -> Bool {
    if !isValid {
      return false
    }
    
    var buf = value
    let rc  = setsockopt(fd!, SOL_SOCKET, option, &buf,socklen_t(sizeof(Int32)))
    
    if rc != 0 { // ps: Great Error Handling
      println("Could not set option \(option) on socket \(self)")
    }
    return rc == 0
  }
  
  // TBD: Can't overload optionals in a useful way?
  // func getSocketOption(option: Int32) -> Int32
  public func getSocketOption(option: Int32) -> Int32? {
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
  
  public func setSocketOption(option: Int32, value: Bool) -> Bool {
    return setSocketOption(option, value: value ? 1 : 0)
  }
  public func getSocketOption(option: Int32) -> Bool {
    let v: Int32? = getSocketOption(option)
    return v != nil ? (v! == 0 ? false : true) : false
  }
  
}


extension Socket { // poll()
  
  public var isDataAvailable: Bool { return pollFlag(POLLRDNORM) }
  
  public func pollFlag(flag: Int32) -> Bool {
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
  
  public func poll(events: Int32, timeout: UInt? = 0) -> Int32? {
    // This is declared as Int32 because the POLLRDNORM and such are
    if !isValid {
      return nil
    }
    
    let ctimeout = timeout != nil ? Int32(timeout!) : -1 /* wait forever */
    
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
  
  public var description : String {
    return "<Socket:" + descriptionAttributes() + ">"
  }
  
}


extension Socket: BooleanType {
  
  public var boolValue : Bool {
    return isValid
  }
  
}

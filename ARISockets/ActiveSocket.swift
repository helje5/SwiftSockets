//
//  ActiveSocket.swift
//  TestSwiftyCocoa
//
//  Created by Helge Hess on 6/11/14.
//  Copyright (c) 2014 Helge Hess. All rights reserved.
//

import Darwin
import Dispatch

/**
* Represents an active STREAM socket based on the standard Unix sockets
* library.
*
* An active socket can be either a socket gained by calling accept on a
* passive socket or by explicitly connecting one to an address (a client
* socket).
* Therefore an active socket has two addresses, the local and the remote one.
*
* There are three methods to perform a close, this is rooted in the fact that
* a socket actually is full-duplex, it provides a send and a receive channel.
* The stream-mode is updated according to what channels are open/closed.
* Initially the socket is full-duplex and you cannot reopen a channel that was
* shutdown. If you have shutdown both channels the socket can be considered
* closed.
*/
class ActiveSocket: Socket, OutputStream {
  
  var remoteAddress:  sockaddr_in?       = nil
  var queue:          dispatch_queue_t?  = nil
  var readSource:     dispatch_source_t? = nil
  var sendCount:      Int                = 0
  var closeRequested: Bool               = false
  
  var isConnected: Bool {
    return isValid ? (remoteAddress != nil) : false
  }
  
  var onRead: ((ActiveSocket) -> Void)? = nil {
    didSet {
      if onRead {
        if readSource == nil {
          startEventHandler()
        }
      }
      else if (readSource) {
        stopEventHandler()
      }
    }
  }
  
  // let the socket own the read buffer, what is the best buffer type?
  var readBuffer     : CChar[] =  CChar[](count: 4096 + 2, repeatedValue: 42)
  var readBufferSize : Int = 4096 { // available space, a bit more for '\0'
    didSet {
      if readBufferSize != oldValue {
        readBuffer = CChar[](count: readBufferSize + 2, repeatedValue: 42)
      }
    }
  }

  
  /* init */
  
  convenience init(fd: CInt?, remoteAddress: sockaddr_in?,
                   queue: dispatch_queue_t? = nil)
  {
    self.init(fd: fd)
    
    self.remoteAddress  = remoteAddress
    self.queue          = queue
  }
  
  
  /* close */
  
  override func close() {
    if !isValid { // already closed
      return
    }
    
    if sendCount > 0 {
      closeRequested = true
      return
    }
    
    stopEventHandler()
    onRead = nil // break potential cycles
    queue  = nil // explicitly release, might be a good idea ;-)
    
    super.close()
  }
  
  
  /* connect */
  
  func connect(address: sockaddr_in, onConnect: () -> Void) -> Bool {
    // FIXME: make connect() asynchronous via GCD
    if !isValid {
      return false
    }
    if isConnected {
      // TBD: could be tolerant if addresses match
      println("Socket is already connected \(self)")
      return false
    }
    
    // Note: must be 'var' for ptr stuff, can't use let
    var addr = address
    
    // CAST: Hope this works, essentially cast to void and then take the rawptr
    let bvptr: CConstVoidPointer = &addr
    let bptr = CConstPointer<sockaddr>(nil, bvptr.value)
    
    // connect!
    let rc = Darwin.connect(fd!, bptr, socklen_t(addr.len));
    if rc != 0 {
      println("Could not connect \(self) to \(addr)")
      return false
    }
    
    remoteAddress = addr
    onConnect()
    
    return true
  }
  
  /* setup event handler */
  
  func stopEventHandler() {
    if readSource {
      dispatch_source_cancel(readSource)
      readSource = nil // abort()s if source is not resumed ...
    }
  }
  
  func startEventHandler() -> Bool {
    if readSource {
      println("Read source already setup?")
      return true // already setup
    }
    
    /* do we have a queue? */
    
    if queue == nil {
      println("No queue set, using main queue")
      queue = dispatch_get_main_queue()
    }
    
    /* setup GCD dispatch source */
    
    readSource = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_READ,
      UInt(fd!), // is this going to bite us?
      0,
      queue
    )
    if !readSource {
      println("Could not create dispatch source for socket \(self)")
      return false
    }
    
    dispatch_source_set_event_handler(readSource) {
      [weak self] in // maybe use unowned
      if self {
        if let cb = self!.onRead {
          cb(self!)
        }
      }
    }
    
    /* actually start listening ... */
    dispatch_resume(readSource)
    
    return true
  }
  
  func asyncWrite(buffer: CChar[], length: Int? = nil) -> Bool {
    if !isValid { // ps: awesome error handling
      println("Socket closed, can't do async writes anymore")
      return false
    }
    
    let bufsize = length ? UInt(length!) : UInt(buffer.count)
    if bufsize < 1 { // Nothing to write ..
      return true
    }
    
    if queue == nil {
      println("No queue set, using main queue")
      queue = dispatch_get_main_queue()
    }
    
    // the default destructor is supposed to copy the data. Not good, but
    // handling ownership is going to be messy
    var asyncData  : dispatch_data_t? = nil
    asyncData = dispatch_data_create(buffer, bufsize, queue,
                                     DISPATCH_DATA_DESTRUCTOR_DEFAULT)
    
    sendCount++
    // in here we capture self, which I think is right.
    dispatch_write(fd!, asyncData, queue) {
      asyncData, error in
      self.sendCount = self.sendCount - 1 // -- fails?
      
      if self.sendCount == 0 && self.closeRequested {
        self.close()
        self.closeRequested = false
      }
    }
    
    return true
  }

  func send(buffer: CChar[], length: Int? = nil) -> Int {
    var writeCount : Int = 0
    let bufsize    = length ? UInt(length!) : UInt(buffer.count)
    let fd         = self.fd!

    buffer.withUnsafePointerToElements {
      p in
      writeCount = Darwin.write(fd, p, bufsize)
    }
    return writeCount
  }

  func read() -> ( Int, CChar[]) {
    var readCount: Int = 0
    let bufsize = UInt(readBufferSize)
    let fd      = self.fd!

    readBuffer.withUnsafePointerToElements {
      p in readCount = Darwin.read(fd, p, bufsize)
    }
    
    if readCount < 0 {
      println("Socket error, check errno.")
      readBuffer[0] = 0
      return ( readCount, readBuffer )
    }
    
    readBuffer[readCount] = 0 // convenience
    return ( readCount, readBuffer )
  }
  
  func numberOfAvailableBytesNoIOCTL() -> Int {
    var len: Int = 0
    
    /* not sure how to get to ioctl
    while (ioctl(fd!, FIONREAD, &len) == -1) {
      if (errno == EINTR)
        continue;
    }
    */

    return len
  }
  
  var isDataAvailable: Bool { return pollFlag(POLLRDNORM) }
  
  func pollFlag(flag: CInt) -> Bool {
    let rc: CInt? = poll(flag, timeout: 0)
    if let flags = rc {
      if (flags & flag) != 0 {
        return true
      }
    }
    return false
  }
  
  let pollEverythingMask: CInt = ( POLLIN | POLLPRI | POLLOUT
                                 | POLLRDNORM | POLLWRNORM
                                 | POLLRDBAND | POLLWRBAND)
  
  let debugPoll = false // put here to avoid 'will never be executed' warning
  
  func poll(events: CInt, timeout: UInt? = 0) -> CInt? {
    // This is declared as CInt because the POLLRDNORM and such are
    if !isValid {
      return nil
    }
    
    let ctimeout = timeout ? CInt(timeout!) : -1 /* wait forever */
    
    var fds = pollfd(fd: fd!, events: CShort(events), revents: 0)
    let rc  = Darwin.poll(&fds, 1, ctimeout)
    
    if rc < 0 {
      println("poll() returned an error")
      return nil
    }
    
    if debugPoll {
      var s = ""
      let mask = CInt(fds.revents)
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
    
    return CInt(fds.revents)
  }
  
  
  // This doesn't work, can't override a stored property
  // Leaving this feature alone for now, doesn't have real-world importance
  // @lazy override var boundAddress: sockaddr_in? = getRawAddress()
  
  
  /* OutputStream (if I move this to an Extension => swiftc sefaults */

  var encoding: UInt { return NSUTF8StringEncoding }
  
  func write(string: String) {
    if let buffer = string.cStringUsingEncoding(encoding) {
      if buffer.count > 0 {
        self.asyncWrite(buffer)
      }
    }
  }
  
  
  /* description */
  
  override func descriptionAttributes() -> String {
    var s = super.descriptionAttributes()
    if remoteAddress {
      s += " remote=\(remoteAddress)"
    }
    return s
  }
}

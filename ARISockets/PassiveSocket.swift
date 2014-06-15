//
//  PassiveSocket.swift
//  TestSwiftyCocoa
//
//  Created by Helge Hess on 6/11/14.
//  Copyright (c) 2014 Helge Hess. All rights reserved.
//

import Darwin
import Dispatch

/*
* Represents a STREAM server socket based on the standard Unix sockets library.
*
* A passive socket has exactly one address, the address the socket is bound to.
* If you do not bind the socket, the address is determined after the listen()
* call was executed through the getsockname() call.
*
* Note that if the socket is bound it's still an active socket from the
* system's PoV, it becomes an passive one when the listen call is executed.
*/
class PassiveSocket: Socket {
  
  var backlog:      Int? = nil
  var isListening:  Bool { return backlog ? true : false; }
  var listenSource: dispatch_source_t?
  
  /* init */
  
  convenience init(address: sockaddr_in) {
    self.init(domain: sockaddr_in.domain, type: SOCK_STREAM)
    
    if isValid {
      reuseAddress = true
      if !bind(address) {
        close() // TBD: how to signal error state in Swift?
      }
    }
  }
  
  /* proper close */
  
  override func close() {
    if listenSource {
      dispatch_source_cancel(listenSource)
      listenSource = nil
    }
    super.close()
  }
  
  /* start listening */
  
  func listen(backlog: Int = 5) -> Bool {
    if !isValid {
      return false
    }
    if isListening {
      return true
    }
    
    let rc = Darwin.listen(fd!, CInt(backlog))
    if (rc != 0) {
      return false
    }
    self.backlog = backlog
    return true
  }
  
  func listen(queue: dispatch_queue_t, backlog: Int = 5,
              accept: (ActiveSocket) -> Void)
    -> Bool
  {
    if !isValid {
      return false
    }
    if isListening {
      return false
    }
    
    /* setup GCD dispatch source */
    
    listenSource = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_READ,
      UInt(fd!), // is this going to bite us?
      0,
      queue
    )
    
    if listenSource {
      let lfd = fd! // please the closure and don't capture self
      
      dispatch_source_set_event_handler(listenSource) {
        do {
          // FIXME: tried to encapsulate this in a sockaddrbuf which does all
          //        the ptr handling, but it ain't work (autoreleasepool issue?)
          var baddr    = sockaddr_in()
          var baddrlen = socklen_t(baddr.len)
          
          // CAST: Hope this works, esntly cast to void and then take the rawptr
          let bvptr: CMutableVoidPointer = &baddr
          let bptr = CMutablePointer<sockaddr>(owner: nil, value: bvptr.value)
          
          let newFD = Darwin.accept(lfd, bptr, &baddrlen)
          
          if newFD != -1 {
            // we pass over the queue, seems convenient. Not sure what kind of
            // queue setup a typical server would want to have
            let newSocket =
              ActiveSocket(fd: newFD, remoteAddress: baddr, queue: queue)
            
            accept(newSocket)
          }
          else { // great logging as Paul says
            println("Failed to accept() socket: \(self)")
          }
          
          // FIXME: check whether there are additional sockets waiting in the
          //        queue? We probably only get one event call even if there is
          //        a backlog
          // But there is no ioctl?
        } while (false);
      }
      
      dispatch_resume(listenSource)
      
      let listenOK = listen(backlog: backlog)
      
      if (listenOK) {
        return true
      }
      else {
        dispatch_source_cancel(listenSource)
        listenSource = nil
      }
    }
    
    return false
  }
  
  
  /* description */
  
  override func descriptionAttributes() -> String {
    var s = super.descriptionAttributes()
    if isListening {
      s += " listening"
    }
    return s
  }
}

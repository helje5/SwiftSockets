//
//  SocketAddress.swift
//  TestSwiftyCocoa
//
//  Created by Helge Heß on 6/12/14.
//  Copyright (c) 2014 Helge Hess. All rights reserved.
//

import Darwin
// import Darwin.POSIX.netinet.`in` - this doesn't seem to work
// import struct Darwin.POSIX.netinet.`in`.sockaddr_in - neither

let INADDR_ANY = in_addr(s_addr: 0)

func ==(lhs: in_addr, rhs: in_addr) -> Bool {
  return __uint32_t(lhs.s_addr) == __uint32_t(rhs.s_addr)
}

extension in_addr {

  init() {
    s_addr = INADDR_ANY.s_addr
  }
  
  init(string: String?) {
    if let s = string {
      if s.isEmpty {
        s_addr = INADDR_ANY.s_addr
      }
      else {
        var buf = INADDR_ANY // Swift wants some initialization
        
        // HACK: Seems to be an NSString bridging problem. If I put in a
        //       value I got from NSTextField, withCString() has an NPE
        //       crash.
        //       Looking in the debugger it seems that the Swift string itself
        //       doesn't seem to have a buffer (because it's backed by
        //       NSString?)
        let sz = String(s) + "" // enforce a copy
        
        sz.withCString { cs in inet_pton(AF_INET, cs, &buf) }
        s_addr = buf.s_addr
      }
    }
    else {
      s_addr = INADDR_ANY.s_addr
    }
  }
  
  var asString: String {
    if self == INADDR_ANY {
      return "*.*.*.*"
    }
    
    let len   = Int(INET_ADDRSTRLEN) + 2
    var buf   = CChar[](count: len, repeatedValue: 0)
    
    var selfCopy = self // &self doesn't work, because it can be const?
    let cs = inet_ntop(AF_INET, &selfCopy, &buf, socklen_t(len))
    
    return String.fromCString(cs)
  }
  
}

extension in_addr: Printable {
  
  var description: String {
    return asString
  }
    
}

protocol SocketAddress {
  
  class var domain: CInt { get }
  
  init() // create empty address, to be filled by eg getsockname()
  
  var len: __uint8_t { get }
}

extension sockaddr_in: SocketAddress {
  
  static var domain = AF_INET // if you make this a let, swiftc segfaults
  static var size = __uint8_t(sizeof(sockaddr_in)) // how to refer to self?
  
  init() {
    sin_len    = sockaddr_in.size
    sin_family = sa_family_t(sockaddr_in.domain)
    sin_port   = 0
    sin_addr   = INADDR_ANY
    sin_zero   = (0,0,0,0,0,0,0,0)
  }
  
  init(port: Int?, address: in_addr = INADDR_ANY) {
    self.init()
    
    sin_port = port ? in_port_t(htons(CUnsignedShort(port!))) : 0
    sin_addr = address
  }
  
  init(port: Int?, address: String?) {
    let isWildcard = address ? (address! == "*" || address! == "*.*.*.*"):true;
    let ipv4       = isWildcard ? INADDR_ANY : in_addr(string: address)
    self.init(port: port, address: ipv4)
  }
  
  var port: Int { // should we make that optional and use wildcard as nil?
    get {
      return Int(ntohs(sin_port))
    }
    set {
      sin_port = in_port_t(htons(CUnsignedShort(newValue)))
    }
  }
  
  var address: in_addr {
    return sin_addr
  }
  
  var isWildcardPort:    Bool { return sin_port == 0 }
  var isWildcardAddress: Bool { return sin_addr == INADDR_ANY }
  
  var len: __uint8_t { return sockaddr_in.size }

  var asString: String {
    let addr = address.asString
    return isWildcardPort ? addr : "\(addr):\(port)"
  }
}

extension sockaddr_in: Printable {
  
  var description: String {
    return asString
  }
  
}

extension sockaddr_in6: SocketAddress {
  
  static var domain = AF_INET6
  static var size   = __uint8_t(sizeof(sockaddr_in6))
  
  init() {
    sin6_len      = sockaddr_in6.size
    sin6_family   = sa_family_t(sockaddr_in.domain)
    sin6_port     = 0
    sin6_flowinfo = 0
    sin6_addr     = in6addr_any
    sin6_scope_id = 0
  }
  
  var port: Int {
    get {
      return Int(ntohs(sin6_port))
    }
    set {
      sin6_port = in_port_t(htons(CUnsignedShort(newValue)))
    }
  }
  
  var isWildcardPort: Bool { return sin6_port == 0 }
  
  var len: __uint8_t { return sockaddr_in6.size }
}

extension sockaddr_un: SocketAddress {
  // TBD: sockaddr_un would be interesting as the size of the structure is
  //      technically dynamic (embedded string)
  
  static var domain = AF_UNIX
  static var size   = __uint8_t(sizeof(sockaddr_un)) // CAREFUL
  
  init() {
    sun_len    = sockaddr_un.size // CAREFUL - kinda wrong
    sun_family = sa_family_t(sockaddr_un.domain)
    
    // Autsch!
    sun_path   = (
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0
    );
  }
  
  var len: __uint8_t {
    // FIXME?: this is wrong. It needs to be the base size + string length in
    //         the buffer
    return sockaddr_un.size
  }
}

//
//  UnixUtils.swift
//  SwiftSockets
//
//  Created by Helge Hess on 6/10/14.
//  Copyright (c) 2014-2017 Always Right Institute. All rights reserved.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

// import xsys - struct in here


// MARK: - network utility functions

func ntohs(_ value: CUnsignedShort) -> CUnsignedShort {
  // FIXME: Swift has this builtin
  // hm, htons is not a func in OSX and the macro is not mapped
  return (value << 8) + (value >> 8);
}
let htons = ntohs // same thing, swap bytes :-)



// MARK: - dispatch convenience

import Dispatch

extension DispatchSourceProtocol {
  
  func onEvent(cb: @escaping (DispatchSourceProtocol, UInt) -> Void) {
    self.setEventHandler {
      let data = self.data
      cb(self, data)
    }
  }
}


// MARK: - Replicate C shims - BAD HACK
// TODO: not required anymore? varargs work on Linux?
//       but not in Xcode yet?

private let dlHandle = xsys.dlopen(nil, RTLD_NOW)
private let fnFcntl  = xsys.dlsym(dlHandle, "fcntl")
private let fnIoctl  = xsys.dlsym(dlHandle, "ioctl")

typealias fcntlViType  =
    @convention(c) (Int32, Int32, Int32) -> Int32
typealias ioctlVipType =
    @convention(c) (Int32, CUnsignedLong, UnsafeMutablePointer<Int32>) -> Int32

// this works on Linux x64 and OSX 10.11/Intel, but obviously this depends on
// the ABI and is pure luck aka Wrong
public func ari_fcntlVi(_ fildes: Int32, _ cmd: Int32, _ val: Int32) -> Int32 {
  let fp = unsafeBitCast(fnFcntl, to: fcntlViType.self)
  return fp(fildes, cmd, val)
}
public func ari_ioctlVip(_ fildes: Int32, _ cmd: CUnsignedLong,
                         _ val: UnsafeMutablePointer<Int32>) -> Int32
{
  let fp = unsafeBitCast(fnIoctl, to: ioctlVipType.self)
  return fp(fildes, cmd, val)
}

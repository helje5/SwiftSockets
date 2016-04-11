//
//  UnixUtils.swift
//  SwiftSockets
//
//  Created by Helge Hess on 6/10/14.
//  Copyright (c) 2014-2015 Always Right Institute. All rights reserved.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

// import xsys - struct in here


// MARK: - network utility functions

func ntohs(value: CUnsignedShort) -> CUnsignedShort {
  // hm, htons is not a func in OSX and the macro is not mapped
  return (value << 8) + (value >> 8);
}
let htons = ntohs // same thing, swap bytes :-)



// MARK: - dispatch convenience

import Dispatch

extension dispatch_source_t {
  
  func onEvent(cb: (dispatch_source_t, CUnsignedLong) -> Void) {
    dispatch_source_set_event_handler(self) {
      let data = dispatch_source_get_data(self)
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

func ari_fcntlVi(fildes: Int32, _ cmd: Int32, _ val: Int32) -> Int32 {
  // this works on Linux x64 and OSX 10.11/Intel, but obviously this depends on
  // the ABI and is pure luck aka Wrong
#if swift(>=3.0)
  let fp = unsafeBitCast(fnFcntl, to: fcntlViType.self)
#else
  let fp = unsafeBitCast(fnFcntl, fcntlViType.self)
#endif
  return fp(fildes, cmd, val)
}
func ari_ioctlVip(fildes: Int32, _ cmd: CUnsignedLong,
                  _ val: UnsafeMutablePointer<Int32>) -> Int32
{
  // this works on Linux x64 and OSX 10.11/Intel, but obviously this depends on
  // the ABI and is pure luck aka Wrong
#if swift(>=3.0)
  let fp = unsafeBitCast(fnIoctl, to: ioctlVipType.self)
#else
  let fp = unsafeBitCast(fnIoctl, ioctlVipType.self)
#endif
  return fp(fildes, cmd, val)
}

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


// MARK: - network utility functions

func ntohs(value: CUnsignedShort) -> CUnsignedShort {
  // hm, htons is not a func in OSX and the macro is not mapped
  return (value << 8) + (value >> 8);
}
let htons = ntohs // same thing, swap bytes :-)



// MARK: - ioctl / ioccom stuff

let IOC_OUT  : CUnsignedLong = 0x40000000

// hh: not sure this is producing the right value
let FIONREAD : CUnsignedLong =
  ( IOC_OUT
  | ((CUnsignedLong(sizeof(Int32)) & CUnsignedLong(IOCPARM_MASK)) << 16)
  | (102 /* 'f' */ << 8) | 127)


/* dispatch convenience */

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

private let dlHandle = Darwin.dlopen(nil, RTLD_NOW)
private let fnFcntl  = Darwin.dlsym(dlHandle, "fcntl")
private let fnIoctl  = Darwin.dlsym(dlHandle, "ioctl")

typealias fcntlViType  =
    @convention(c) (Int32, Int32, Int32) -> Int32
typealias ioctlVipType =
    @convention(c) (Int32, CUnsignedLong, UnsafeMutablePointer<Int32>) -> Int32

func ari_fcntlVi(fildes: Int32, _ cmd: Int32, _ val: Int32) -> Int32 {
  // this works on Linux x64 and OSX 10.11/Intel, but obviously this depends on
  // the ABI and is pure luck aka Wrong
  let fp = unsafeBitCast(fnFcntl, fcntlViType.self)
  return fp(fildes, cmd, val)
}
func ari_ioctlVip(fildes: Int32, _ cmd: CUnsignedLong,
                  _ val: UnsafeMutablePointer<Int32>) -> Int32
{
  // this works on Linux x64 and OSX 10.11/Intel, but obviously this depends on
  // the ABI and is pure luck aka Wrong
  let fp = unsafeBitCast(fnIoctl, ioctlVipType.self)
  return fp(fildes, cmd, val)
}

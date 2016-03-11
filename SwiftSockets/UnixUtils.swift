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

#if os(Linux)
let sysFIONREAD : CUnsignedLong = CUnsignedLong(Glibc.FIONREAD)
#else /* os(Darwin) */
// TODO: still required?
let IOC_OUT  : CUnsignedLong = 0x40000000

// hh: not sure this is producing the right value
let FIONREAD : CUnsignedLong =
  ( IOC_OUT
  | ((CUnsignedLong(sizeof(Int32)) & CUnsignedLong(IOCPARM_MASK)) << 16)
  | (102 /* 'f' */ << 8) | 127)
let sysFIONREAD = FIONREAD
#endif /* os(Darwin) */

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

private let dlHandle = sysDlopen(nil, RTLD_NOW)
private let fnFcntl  = sysDlsym(dlHandle, "fcntl")
private let fnIoctl  = sysDlsym(dlHandle, "ioctl")

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


// MARK: - Wrap system naming differences

typealias sysOpenType = (UnsafePointer<CChar>, CInt) -> CInt

#if os(Linux)
import Glibc

public enum POSIXError : CInt {
  case EPERM
}

let sysOpen        : sysOpenType = Glibc.open
let sysClose       = Glibc.close
let sysRead        = Glibc.read
let sysWrite       = Glibc.write
let sysPoll        = Glibc.poll
let sysBind        = Glibc.bind
let sysConnect     = Glibc.connect
let sysListen      = Glibc.listen
let sysAccept      = Glibc.accept
let sysShutdown    = Glibc.shutdown
let sysGetsockname = Glibc.getsockname
let sysGetpeername = Glibc.getpeername
let sysDlsym       = Glibc.dlsym
let sysDlopen      = Glibc.dlopen

var sysErrno : Int32 { return Glibc.errno }

let sys_SOCK_STREAM : Int32 = Int32(SOCK_STREAM.rawValue)
let sys_SOCK_DGRAM  : Int32 = Int32(SOCK_DGRAM.rawValue)
let sys_SHUT_RD     : Int32 = Int32(SHUT_RD)

#else // os(Darwin)

import Darwin

let sysOpen        : sysOpenType = Darwin.open
let sysClose       = Darwin.close
let sysRead        = Darwin.read
let sysWrite       = Darwin.write
let sysPoll        = Darwin.poll
let sysBind        = Darwin.bind
let sysConnect     = Darwin.connect
let sysListen      = Darwin.listen
let sysAccept      = Darwin.accept
let sysShutdown    = Darwin.shutdown
let sysGetsockname = Darwin.getsockname
let sysGetpeername = Darwin.getpeername
let sysDlsym       = Darwin.dlsym
let sysDlopen      = Darwin.dlopen

var sysErrno : Int32 { return Darwin.errno }

let sys_SOCK_STREAM = SOCK_STREAM
let sys_SOCK_DGRAM  = SOCK_DGRAM
let sys_SHUT_RD     = SHUT_RD

#endif // os(Darwin)

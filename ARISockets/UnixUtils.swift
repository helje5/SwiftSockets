//
//  UnixUtils.swift
//  TestSwiftyCocoa
//
//  Created by Helge Hess on 6/10/14.
//  Copyright (c) 2014 Helge Hess. All rights reserved.
//

import Darwin


/* network utility functions */

func ntohs(value: CUnsignedShort) -> CUnsignedShort {
  // hm, htons is not a func in OSX and the macro is not mapped
  return (value << 8) + (value >> 8);
}
let htons = ntohs // same thing, swap bytes :-)



/* ioctl / ioccom stuff */

let IOC_OUT  : CUnsignedLong = 0x40000000

// hh: not sure this is producing the right value
let FIONREAD : CUnsignedLong =
  ( IOC_OUT
  | ((CUnsignedLong(sizeof(CInt)) & CUnsignedLong(IOCPARM_MASK)) << 16)
  | (102 /* 'f' */ << 8) | 127)

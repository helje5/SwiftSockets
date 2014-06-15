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

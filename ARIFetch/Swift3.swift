//
//  Swift3.swift
//  SwiftSockets
//
//  Created by Helge Hess on 06/06/16.
//
//

import Foundation

#if swift(>=3.0) // #swift3-cstr
extension String {

  static func fromCString(_ cs: UnsafePointer<CChar>) -> String? {
    return String(fromCString(cs))
  }
  
}
#endif

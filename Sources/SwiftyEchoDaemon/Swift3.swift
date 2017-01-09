//
//  Swift3.swift
//  SwiftSockets
//
//  Created by Helge Hess on 06/06/16.
//
//

extension String {

  static func fromCString(_ cs: UnsafePointer<CChar>) -> String? {
    return String(fromCString(cs))
  }
  
}

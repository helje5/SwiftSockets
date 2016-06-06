//
//  Swift3.swift
//  SwiftSockets
//
//  Created by Helge Hess on 06/06/16.
//
//

import Foundation

#if swift(>=3.0) // #swift3-fd #swift3-cstr
extension String {

  static func fromCString(_ cs: UnsafePointer<CChar>) -> String? {
    return String(fromCString(cs))
  }
  
}
#else // Swift 2.2
extension String {
  func index(before idx: Index) -> Index { return idx.predecessor() }
}
extension Dictionary {
  
  mutating func removeValue(forKey k: Key) -> Value? {
    return removeValueForKey(k)
  }
  
}
#endif // Swift 2.2

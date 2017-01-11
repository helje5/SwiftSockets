//
//  Swift3.swift
//  SwiftSockets
//
//  Created by Helge Hess on 06/06/16.
//
//

extension String {
  func index(before idx: Index) -> Index { return idx.predecessor() }
}
extension Dictionary {
  
  mutating func removeValue(forKey k: Key) -> Value? {
    return removeValueForKey(k)
  }
  
}

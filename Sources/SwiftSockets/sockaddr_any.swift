//
//  sockaddr_any.swift
//  SwiftSockets
//
//  Created by Helge Hess on 12/04/16.
//
//

// Note: This cannot conform to SocketAddress because it doesn't have a static
//       domain.
public enum sockaddr_any {
  
  case AF_INET (sockaddr_in)
  case AF_INET6(sockaddr_in6)
  case AF_LOCAL(sockaddr_un)
  
  public var domain: Int32 {
    switch self {
    case .AF_INET:  return xsys.AF_INET
    case .AF_INET6: return xsys.AF_INET6
    case .AF_LOCAL: return xsys.AF_LOCAL
    }
  }
  
  public var len: __uint8_t {
    #if os(Linux)
      switch self {
      case .AF_INET:  return __uint8_t(strideof(sockaddr_in))
      case .AF_INET6: return __uint8_t(strideof(sockaddr_in6))
      case .AF_LOCAL: return __uint8_t(strideof(sockaddr_un)) // TODO: wrong
      }
    #else
      switch self {
      case .AF_INET (let addr): return addr.sin_len
      case .AF_INET6(let addr): return addr.sin6_len
      case .AF_LOCAL(let addr): return addr.sun_len
      }
    #endif
  }
}

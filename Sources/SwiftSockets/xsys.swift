//
//  xsys.swift
//  SwiftSockets
//
//  Created by Helge Hess on 11/04/16.
//
//

// Note: This is eventually going to be a module with proper globals, to embed
//       it, we use a struct.

public typealias xsysOpenType = (UnsafePointer<CChar>, CInt) -> CInt

#if os(Linux)
  import Glibc

  public typealias sa_family_t = Glibc.sa_family_t
  
  // using an exact alias gives issues with sizeof()
  public typealias xsys_sockaddr     = Glibc.sockaddr
  public typealias xsys_sockaddr_in  = Glibc.sockaddr_in
  public typealias xsys_sockaddr_in6 = Glibc.sockaddr_in6
  public typealias xsys_sockaddr_un  = Glibc.sockaddr_un
  
  public typealias addrinfo     = Glibc.addrinfo
  public typealias socklen_t    = Glibc.socklen_t
  
  public struct xsys {
    // dylib
    public static let dlsym  = Glibc.dlsym
    public static let dlopen = Glibc.dlopen
    
    // fd
    public static let open  : xsysOpenType = Glibc.open
    public static let close = Glibc.close
    public static let read  = Glibc.read
    public static let write = Glibc.write
    
    // socket
    public static let socket      = Glibc.socket
    public static let poll        = Glibc.poll
    public static let bind        = Glibc.bind
    public static let connect     = Glibc.connect
    public static let listen      = Glibc.listen
    public static let accept      = Glibc.accept
    public static let shutdown    = Glibc.shutdown
    
    public static let getsockname = Glibc.getsockname
    public static let getpeername = Glibc.getpeername
    
    public static let SOCK_STREAM : Int32 = Int32(Glibc.SOCK_STREAM.rawValue)
    public static let SOCK_DGRAM  : Int32 = Int32(Glibc.SOCK_DGRAM.rawValue)
    public static let SHUT_RD     : Int32 = Int32(Glibc.SHUT_RD)
    
    public static let AF_UNSPEC   = Glibc.AF_UNSPEC
    public static let AF_INET     = Glibc.AF_INET
    public static let AF_INET6    = Glibc.AF_INET6
    public static let AF_LOCAL    = Glibc.AF_LOCAL
    public static let PF_UNSPEC   = Glibc.PF_UNSPEC

    // POSIXError
    public static var errno : Int32 { return Glibc.errno }
    
    // ioctl
    public static let FIONREAD : CUnsignedLong = CUnsignedLong(Glibc.FIONREAD)
    public static let fcntlVi  = ari_fcntlVi
    public static let ioctlVip = ari_ioctlVip
  }

  public enum POSIXError : CInt {
    case EPERM
  }
#else
  import Darwin
  
  public typealias sa_family_t = Darwin.sa_family_t
  
  // using an exact alias gives issues with sizeof()
  public typealias xsys_sockaddr     = Darwin.sockaddr
  public typealias xsys_sockaddr_in  = Darwin.sockaddr_in
  public typealias xsys_sockaddr_in6 = Darwin.sockaddr_in6
  public typealias xsys_sockaddr_un  = Darwin.sockaddr_un
  
  public typealias addrinfo     = Darwin.addrinfo
  public typealias socklen_t    = Darwin.socklen_t
  
  public struct xsys {
    // dylib
    public static let dlsym  = Darwin.dlsym
    public static let dlopen = Darwin.dlopen
    
    // fd
    public static let open  : xsysOpenType = Darwin.open
    public static let close = Darwin.close
    public static let read  = Darwin.read
    public static let write = Darwin.write

    // socket
    public static let socket      = Darwin.socket
    public static let poll        = Darwin.poll
    public static let bind        = Darwin.bind
    public static let connect     = Darwin.connect
    public static let listen      = Darwin.listen
    public static let accept      = Darwin.accept
    public static let shutdown    = Darwin.shutdown
    public static let getsockname = Darwin.getsockname
    public static let getpeername = Darwin.getpeername
    
    public static let SOCK_STREAM = Darwin.SOCK_STREAM
    public static let SOCK_DGRAM  = Darwin.SOCK_DGRAM
    public static let SHUT_RD     = Darwin.SHUT_RD
    
    public static let AF_UNSPEC   = Darwin.AF_UNSPEC
    public static let AF_INET     = Darwin.AF_INET
    public static let AF_INET6    = Darwin.AF_INET6
    public static let AF_LOCAL    = Darwin.AF_LOCAL
    public static let PF_UNSPEC   = Darwin.PF_UNSPEC
    
    // POSIXError
    public static var errno : Int32 { return Darwin.errno }
    
    // ioctl
    // TODO: still required?
    public static let IOC_OUT  : CUnsignedLong = 0x40000000
    
    // hh: not sure this is producing the right value
    public static let FIONREAD : CUnsignedLong =
      ( IOC_OUT
        | ((CUnsignedLong(sizeof(Int32)) & CUnsignedLong(IOCPARM_MASK)) << 16)
        | (102 /* 'f' */ << 8) | 127)
    public static let fcntlVi  = ari_fcntlVi
    public static let ioctlVip = ari_ioctlVip
  }
#endif

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
    
    // POSIXError
    public static var errno : Int32 { return Glibc.errno }
    
    // ioctl
    public static let FIONREAD : CUnsignedLong = CUnsignedLong(Glibc.FIONREAD)
  }

  public enum POSIXError : CInt {
    case EPERM
  }
#else
  import Darwin
  
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
  }
#endif

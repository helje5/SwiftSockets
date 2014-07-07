//
//  DNS.swift
//  ARISockets
//
//  Created by Helge Hess on 7/3/14.
//
//
import Darwin

func gethoztbyname<T: SocketAddress>
  (name : String, flags : CInt = AI_CANONNAME,
   cb   : ( String, String?, T? ) -> Void)
{
  // Note: I can't just provide a name and a cb, swiftc will complain.
  var hints = addrinfo()
  hints.ai_flags  = flags  // AI_CANONNAME, AI_NUMERICHOST, etc
  hints.ai_family = T.domain
  
  var ptr     = UnsafePointer<addrinfo>(nil)
  let nullptr : UnsafePointer<addrinfo> = UnsafePointer.null()
  
  /* run lookup (synchronously, can be slow!) */
  var rc = name.withCString { (cs : CString) -> CInt in
    getaddrinfo(cs, CString(nil), &hints, &ptr)
  }
  if rc != 0 {
    cb(name, nil, nil)
    return
  }
  
  /* copy results - we just take the first match */
  var cn   : String? = nil
  var addr : T?      = ptr.memory.address()
  if rc == 0 && ptr != nullptr {
    cn   = ptr.memory.canonicalName
    addr = ptr.memory.address()
  }
  
  /* free OS resources */
  freeaddrinfo(ptr)
  
  /* report results */
  cb(name, cn, addr)
}

/* swiftc crashes, can't get this right (array of tuples)
func gethostzbyname<T: SocketAddress>
  (name : String, flags : CInt = AI_CANONNAME,
   cb   : [( String, ( cn: String?, address: T?)]? ) -> Void)
{
  // Note: I can't just provide a name and a cb, swiftc will complain.
  var hints = addrinfo()
  hints.ai_flags  = flags  // AI_CANONNAME, AI_NUMERICHOST, etc
  hints.ai_family = T.domain
  
  var ptr     = UnsafePointer<addrinfo>(nil)
  let nullptr : UnsafePointer<addrinfo> = UnsafePointer.null()
  
  /* run lookup (synchronously, can be slow!) */
  var rc = name.withCString { (cs : CString) -> CInt in
    getaddrinfo(cs, CString(nil), &hints, &ptr)
  }
  
  /* copy results - we just take the first match */
  typealias hapair = (cn: String?, address: T?)
  var results : Array<hapair>! = nil
  
  if rc == 0 && ptr != nullptr {
    results = Array<hapair>()
    for info in ptr.memory {
      let pair : hapair = ( info.canonicalName, info.address() )
      results!.append(pair)
    }
  }
  
  /* free OS resources */
  freeaddrinfo(ptr)
  
  /* report results */
  
  cb(name, results)
}
*/

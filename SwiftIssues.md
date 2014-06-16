Issues with Swift
=================

Below a collection of issues I've found in the current implementation of Swift.
Presumably they fix most of them pretty quickly.

FIXME: Collect and list all issues :-)

###Bugs

- swiftc segfaults
  - If I do Socket&lt;T: SocketAddress&gt; (etc). Need to make a branch for that
    - demo branch: feature/generics
  - Moving properties to a class extension (to structure the code)
    - demo branch: feature/structure-code-with-extensions
  - Long constant strings
    - demo branch: feature/long-static-strings
- runtime segfaults
  - withCString on a SwiftString hosted by an NSString (NPE)
- No access to ioctl()
- sizeof() only works on types, not on variables/constants
- Cannot put methods into extensions which are going to be overridden 
  ('declarations in extensions cannot be overridden yet')

###How To?

####Error Handling

I'm not sure how we are supposed to handle errors in Swift. Maybe using some
enum for the error codes and a fallback value (e.g. the file descriptor) for
the success case. Kinda like an Optional, with more fail values than nil.

####Casting C Structures

How should we cast between typed pointers? Eg bind() takes a &sockaddr, but the
actual structure is variable (eg a sockaddr_in).

I hacked around it like this:
```swift
var addr = address // where address is sockaddr_in
    
// CAST: Hope this works, essentially cast to void and then take the rawptr
let bvptr: CConstVoidPointer = &addr
let bptr = CConstPointer<sockaddr>(nil, bvptr.value)
```
Which doesn't feel right.

####Flexible Length C Structures

I guess this can be done with UnsafePointer. Structures like sockaddr_un,
which embed the path within the structure and thereby have a different size.

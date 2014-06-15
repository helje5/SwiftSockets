Issues with Swift
=================

Below a collection of issues I've found in the current implementation of Swift.
Presumably they fix most of them pretty quickly.

FIXME: Collect and list all issues :-)

- No access to ioctl()
- I have no idea on how we are supposed to do error handling in Swift
  - Maybe somehow using enums with an optional containing the value?
- swiftc segfaults
  - If I do Socket<T: SocketAddress> (etc). Need to make a branch for that
  - Moving properties to a class extension (to structure the code)
  - Long constant strings
- runtime segfaults
  - withCString on a SwiftString hosted by an NSString (NPE)

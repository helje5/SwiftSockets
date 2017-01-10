// SwiftyEcho

import Dispatch
#if os(Linux) // for sockaddr_in
import Glibc
let sysSleep = Glibc.sleep
#else
import Darwin
let sysSleep = Darwin.sleep
#endif

let port = 1337

let echod = EchoServer(port: port)
echod.start()

print("Connect in e.g. Terminal via 'telnet 127.0.0.1 \(port)'")

dispatchMain()
// dispatch_main never returns. print("Stopping.")

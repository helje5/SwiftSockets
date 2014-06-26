//
//  AppDelegate.swift
//  ARIFetch
//
//  Created by Helge Hess on 6/13/14.
//
//

import Cocoa
import ARISockets

class AppDelegate: NSObject, NSApplicationDelegate {
                            
  @IBOutlet var window           : NSWindow
  @IBOutlet var resultViewParent : NSScrollView
  @IBOutlet var host             : NSTextField
  @IBOutlet var port             : NSTextField

  var resultView: NSTextView { // NSTextView doesn't work with weak?
    return resultViewParent.contentView.documentView as NSTextView
  }

  func applicationDidFinishLaunching(aNotification: NSNotification?) {
    fetch(nil)
  }

  func applicationWillTerminate(aNotification: NSNotification?) {
    socket?.close()
  }
  
  
  var socket: ActiveSocket?

  @IBAction func fetch(sender: NSTextField?) {
    if let oldSock = socket {
      socket = nil
      oldSock.close()
      resultView.string = "" // clear results
    }
    
    socket = ActiveSocket()
    println("Got socket: \(socket)")
    if !socket {
      return
    }
    
    let s = socket!
    
    s.onRead  { self.handleIncomingData($0, expectedCount: $1) }
    s.onClose { fd in println("Closing \(fd) ..."); }
    
    // connect
    
    let host = self.host.stringValue
    let port = Int(self.port.intValue)
    println("Connect \(host):\(port) ...")
    
    let ok = s.connect(sockaddr_in(address:host, port:port)) {
      println("connected \(s)")
      s.isNonBlocking = true
      
      s.write(
        "GET / HTTP/1.0\r\n" +
        "Content-Length: 0\r\n" +
        "X-Q-AlwaysRight: Yes, indeed\r\n" +
        "\r\n" +
        "\r\n"
      )
    }
    if !ok {
      println("connect failed \(s)")
      s.close()
      socket = nil
    }
  }

  func handleIncomingData(socket: ActiveSocket, expectedCount: Int) {
    do {
      let (count, block, errno) = socket.read()
      
      if count < 0 && errno == EWOULDBLOCK {
        break
      }
    
      println("got bytes: \(count)")
      
      if count < 1 {
        println("EOF \(socket)")
        socket.close()
        return
      }

      println("BLOCK: \(block)")
      var data : String = block.withUnsafePointerToElements {
        p in
        if p != nil {
          // Sometimes fails in: Can't unwrap Optional.None (at bufsize==count?)
          // FIXME: I think I know why. It may happen if the block boundary is
          //        within a UTF-8 sequence?
          // The end of the block is 100,-30,-128,0
          return String.fromCString(p) // this can fail, will abort()
        }
        else {
          println("Could not grab pointer to block \(count) \(block)?")
          return "<ERROR>"
        }
      }
      
      // log to view. Careful, must run in main thread!
      dispatch_async(dispatch_get_main_queue()) {
        self.resultView.appendString(data)
      }
    } while (true)
  }

}

extension NSTextView {
  
  func appendString(string: String) {
    var ls = NSAttributedString(string: string)
    textStorage.appendAttributedString(ls)
    
    let charCount = (self.string as NSString).length
    let r = NSMakeRange(charCount, 0)
    self.scrollRangeToVisible(r)
    
    needsDisplay = true
  }
  
}

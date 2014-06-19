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
    
    s.onRead  { self.handleIncomingData($0) }
    s.onClose { fd in println("Closing \(fd) ..."); }
    
    // connect
    
    let host = self.host.stringValue
    let port = Int(self.port.intValue)
    println("Connect \(host):\(port) ...")
    
    let ok = s.connect(sockaddr_in(address:host, port:port)) {
      println("connected \(s)")
      
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

  func handleIncomingData(socket: ActiveSocket) {
    let (count, block) = socket.read()
    
    println("got bytes: \(count)")
    
    if count < 1 {
      println("EOF \(socket)")
      socket.close()
      return
    }

    var data = ""
    block.withUnsafePointerToElements {
      p in
      data = String.fromCString(p) // this can fail, will abort()
    }
    
    // log to view. Careful, must run in main thread!
    dispatch_async(dispatch_get_main_queue()) {
      self.resultView.appendString(data)
    }
    
    // LAME HACK around the missing ioctl().
    // This is going to block at least queue thread? if a buffer is received
    // which is exactly the size of the readBuffer
    // TBD: maybe we can use poll() on the descriptor to see if sth is waiting?
    // TBD: or make the socket itself unblocking
    if count == socket.readBufferSize {
      println("Got a full buffer, more data waiting? MIGHT BLOCK")
      socket.readCB?(socket) // recurse
    }
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

//
//  AppDelegate.swift
//  ARIEchoServer
//
//  Created by Helge Heß on 6/13/14.
//
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  
  @IBOutlet var window        : NSWindow!
  @IBOutlet var logViewParent : NSScrollView!
  @IBOutlet var label         : NSTextField!
  
  var logView: NSTextView {
    // NSTextView doesn't work with weak?
    return logViewParent.contentView.documentView as! NSTextView
  }
  
  var echod : EchoServer?
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
    let port = 1337
    
    echod = EchoServer(port: port)
    echod!.appLog = { self.log(string: $0) }
    echod!.start()
    
    label.stringValue =
      "Connect in e.g. Terminal via 'telnet 127.0.0.1 \(port)'"
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    echod?.stop()
  }
  
  
  func log(string s: String) {
    // log to shell
    print(s)
    
    // log to view. Careful, must run in main thread!
    dispatch_async(dispatch_get_main_queue()) {
      self.logView.appendString(string: s + "\n")
    }
  }
}

extension NSTextView {
  
  func appendString(string s: String) {
    if let ts = textStorage {
      let ls = NSAttributedString(string: s)
#if swift(>=3.0) // #swift3-1st-kwarg
      ts.append(ls)
#else
      ts.appendAttributedString(ls)
#endif
    }

    let charCount = (s as NSString).length
    self.scrollRangeToVisible(NSMakeRange(charCount, 0))
    needsDisplay = true
  }
  
}


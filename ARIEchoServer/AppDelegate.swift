//
//  AppDelegate.swift
//  ARIEchoServer
//
//  Created by Helge Heß on 6/13/14.
//  Copyright (c) 2014-2017 Always Right Institute. All rights reserved.
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  @IBOutlet var window        : NSWindow!
  @IBOutlet var logViewParent : NSScrollView!
  @IBOutlet var label         : NSTextField!
  
  var logView: NSTextView {
    // NSTextView doesn't work with weak?
    return logViewParent.contentView.documentView as! NSTextView
  }
  
  var echod : EchoServer?
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let port = 1337
    
    echod = EchoServer(port: port)
    echod!.appLog = { self.log(string: $0) }
    echod!.start()
    
    label.stringValue =
      "Connect in e.g. Terminal via 'telnet 127.0.0.1 \(port)'"
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    echod?.stop()
  }
  
  
  func log(string s: String) {
    // log to shell
    print(s)
    
    // log to view. Careful, must run in main thread!
    DispatchQueue.main.async {
      self.logView.appendString(string: s + "\n")
    }
  }
}

extension NSTextView {
  
  func appendString(string s: String) {
    if let ts = textStorage {
      let ls = NSAttributedString(string: s)
      ts.append(ls)
    }

    let charCount = (s as NSString).length
    self.scrollRangeToVisible(NSMakeRange(charCount, 0))
    needsDisplay = true
  }
  
}


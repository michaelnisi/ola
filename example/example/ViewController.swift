//
//  ViewController.swift
//  example
//
//  Created by Michael Nisi on 28.12.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import UIKit
import Ola

class ViewController: UIViewController {
  let session: NSURLSession = {
    let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
    conf.requestCachePolicy = .ReloadIgnoringLocalCacheData
    return NSURLSession(configuration: conf)
  }()

  let queue = NSOperationQueue()
  weak var op: NSOperation?

  @IBAction func cancelUp(sender: UIButton) {
    op?.cancel()
  }
  
  @IBAction func requestUp(sender: UIButton) {
    sender.enabled = false
    let url = NSURL(string: "http://apple.com")
    let q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    let op = Example(session: session, url: url!, queue: q)
    op.completionBlock = {
      dispatch_sync(dispatch_get_main_queue()) {
        sender.enabled = true
      }
    }
    queue.addOperation(op)
    self.op = op
  }
}


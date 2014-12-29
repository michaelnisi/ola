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
  let queue = dispatch_queue_create("ola.example", DISPATCH_QUEUE_SERIAL)
  let session = NSURLSession(
    configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
  let opQueue = NSOperationQueue()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    let url = NSURL(string: "http://apple.com")
    let op = Example(session: session, url: url!, queue: queue)
    op.completionBlock = { println("request completed") }
    opQueue.addOperation(op)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}


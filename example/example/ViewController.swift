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

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    let queue = dispatch_queue_create("ola.example", DISPATCH_QUEUE_SERIAL)
    let host = "apple.com"
    let apple = Ola(host: host, queue: queue)
    apple.reachWithCallback() { status in
      if status == .Reachable {
        println("\(host) is reachable")
      } else {
        println("\(host) is not reachable")
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}


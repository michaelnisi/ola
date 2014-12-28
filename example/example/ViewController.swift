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
    
    let queue = dispatch_queue_create("ola.test", DISPATCH_QUEUE_SERIAL)
    let f = Ola(host: "google.com", queue: queue)
    f.reachWithCallback() { status in
      if status == .Reachable {
        println("google.com is reachable")
      } else {
        println("google.com is not reachable")
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}


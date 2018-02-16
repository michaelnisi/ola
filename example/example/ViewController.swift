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
  let session: URLSession = {
    let conf = URLSessionConfiguration.default
    conf.requestCachePolicy = .reloadIgnoringLocalCacheData
    conf.timeoutIntervalForRequest = 5
    return URLSession(configuration: conf)
  }()

  let queue = OperationQueue()
  weak var op: Operation?

  @IBAction func cancelUp(_ sender: UIButton) {
    op?.cancel()
  }
  
  @IBAction func requestUp(_ sender: UIButton) {
    sender.isEnabled = false
    let url = URL(string: "https://apple.com")
    let op = Example(session: session, url: url!)
    op.completionBlock = { [weak op] in
      if let er = op?.error {
        NSLog("\(#function): completed with error: \(er)")
      } else {
        NSLog("\(#function): ok")
      }
      DispatchQueue.main.sync {
        sender.isEnabled = true
      }
    }
    queue.addOperation(op)
    self.op = op
  }
}


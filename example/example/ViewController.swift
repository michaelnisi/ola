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
  
  lazy var session: URLSession = {
    let conf = URLSessionConfiguration.default
    conf.requestCachePolicy = .reloadIgnoringLocalCacheData
    conf.timeoutIntervalForRequest = 5
    return URLSession(configuration: conf)
  }()
  
  var probe: Ola?
  
  var task: URLSessionTask? {
    willSet {
      task?.cancel()
      probe = nil
    }
  }
  
  @IBAction func valueChanged(_ sender: UISegmentedControl) {
    assert(Thread.isMainThread)
    
    func done() {
      DispatchQueue.main.async {
        self.task = nil
        sender.selectedSegmentIndex = 1
      }
    }
    
    let url = URL(string: "https://apple.com/")!
    
    func check() {
      self.task = nil
      
      guard let p = Ola(host: url.host!) else {
        return done()
      }
      
      self.probe = p
      
      // Simply checking if the host is reachable is the common use case.
      let status = p.reach()
      
      guard (status == .cellular || status == .reachable) else {
        // Unreachable host, installing a callback.
        let ok = p.install { status in
          guard (status == .cellular || status == .reachable) else {
            // Status changed, but host still isn’t reachable, keep waiting.
            return
          }
          // Host supposedly reachable, try again.
          DispatchQueue.main.async {
            self.probe = nil
            self.valueChanged(sender)
          }
        }
        guard ok else {
          // Installing the callback failed.
          return done()
        }
        // Awaiting reachability changes.
        return
      }
      
      valueChanged(sender)
    }

    switch sender.selectedSegmentIndex {
    case 0:
      task = session.dataTask(with: url) { data, response, error in
        guard error == nil else {
          let er = error!
          switch er._code {
          case NSURLErrorCancelled:
            return
          case
          NSURLErrorTimedOut,
          NSURLErrorNotConnectedToInternet,
          NSURLErrorNetworkConnectionLost:
            return check()
          default:
            return done()
          }
        }
        done()
      }
      task?.resume()
    case 1:
      task = nil
    default:
      break
    }
  }
}


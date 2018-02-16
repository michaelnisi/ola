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
    func done() {
      DispatchQueue.main.async {
        sender.selectedSegmentIndex = 1
      }
    }
    
    let url = URL(string: "https://apple.com/")!
    
    func check() {
      guard let p = Ola(host: url.host!) else {
        return done()
      }
      
      probe = p
      
      let status = p.reach()
      guard (status == .cellular || status == .reachable) else {
        let ok = p.reach { status in
          guard (status == .cellular || status == .reachable) else {
            return
          }
          DispatchQueue.main.async {
            self.valueChanged(sender)
          }
        }
        guard ok else {
          return done()
        }
        return
      }
      
      DispatchQueue.main.async {
        self.valueChanged(sender)
      }
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
            check()
            return
          default:
            done()
            return
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


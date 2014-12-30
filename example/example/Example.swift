//
//  Example.swift
//  example
//
//  Created by Michael Nisi on 29.12.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation
import Ola

public class Example: NSOperation {
  let session: NSURLSession
  let url: NSURL
  let queue: dispatch_queue_t
  let sema = dispatch_semaphore_create(0)

  var ola: Ola?
  
  public init (session: NSURLSession, url: NSURL, queue: dispatch_queue_t) {
    self.session = session
    self.url = url
    self.queue = queue
  }
  
  
  func request () {
    let sema = self.sema
    let task = session.dataTaskWithURL(url) { data, response, error in
      if error != nil {
        self.check()
      } else {
        dispatch_semaphore_signal(sema)
      }
    }
    task.resume()
  }
  
  func check () {
    if ola == nil {
      ola = Ola(host: url.host!, queue: queue)
      ola?.reachWithCallback() { status in
        if status == .Reachable { self.request() }
      }
    }
  }
  
  public override func main () {
    request()
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
  }
  
  public override func cancel () {
    dispatch_semaphore_signal(sema)
    super.cancel()
  }
}

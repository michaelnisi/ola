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
  let queue: dispatch_queue_t
  let session: NSURLSession
  let url: NSURL

  public init (session: NSURLSession, url: NSURL, queue: dispatch_queue_t) {
    self.session = session
    self.url = url
    self.queue = queue
  }

  var sema: dispatch_semaphore_t?

  func lock () {
    if !cancelled && sema == nil {
      sema = dispatch_semaphore_create(0)
      dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
    }
  }

  func unlock () {
    if let sema = self.sema {
      dispatch_semaphore_signal(sema)
    }
  }

  weak var task: NSURLSessionTask?

  func request () {
    self.task?.cancel()
    self.task = session.dataTaskWithURL(url) {
      [weak self] data, response, error in
      if self?.cancelled == true {
        return
      }
      if let er = error {
        if er.code != -999 {
          self?.check()
          return
        }
      }
      self?.unlock()
    }
    self.task?.resume()
  }

  var allowsCellularAccess: Bool { get {
    return session.configuration.allowsCellularAccess }
  }

  func reachable (status: OlaStatus) -> Bool {
    return status == .Reachable || (status == .Cellular
      && allowsCellularAccess)
  }

  lazy var ola: Ola? = { [unowned self] in
    Ola(host: self.url.host, queue: self.queue)
  }()

  func check () {
    if let ola = self.ola {
      if reachable(ola.reach()) {
        request()
      } else {
        ola.reachWithCallback() { [weak self] status in
          if self?.cancelled == false
          && self?.reachable(status) == true {
            self?.request()
          }
        }
      }
    } else {
      println("could not initialize ola")
    }
  }

  public override func main () {
    if cancelled {
      return
    }
    request()
    lock()
  }

  public override func cancel () {
    task?.cancel()
    unlock()
    super.cancel()
  }
}

//
//  Example.swift
//  example
//
//  Created by Michael Nisi on 29.12.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation
import Ola

enum ExampleError: ErrorType {
  case Cancelled
}

class Example: NSOperation {

  private var _executing: Bool = false
  
  override var executing: Bool {
    get { return _executing }
    set {
      assert(newValue != _executing)
      willChangeValueForKey("isExecuting")
      _executing = newValue
      didChangeValueForKey("isExecuting")
    }
  }
  
  private var _finished: Bool = false
  
  override var finished: Bool {
    get { return _finished }
    set {
      assert(newValue != _finished)
      willChangeValueForKey("isFinished")
      _finished = newValue
      didChangeValueForKey("isFinished")
    }
  }
  
  let queue: dispatch_queue_t
  let session: NSURLSession
  let url: NSURL

  init(session: NSURLSession, url: NSURL, queue: dispatch_queue_t) {
    self.session = session
    self.url = url
    self.queue = queue
  }
  
  var allowsCellularAccess: Bool { get {
    return session.configuration.allowsCellularAccess }
  }
  
  func reachable(status: OlaStatus) -> Bool {
    return status == .Reachable || (status == .Cellular && allowsCellularAccess)
  }
  
  lazy var ola: Ola? = { [unowned self] in
    Ola(host: self.url.host!, queue: self.queue)
  }()
  
  func check() {
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
      print("could not initialize")
    }
  }
  
  var error: ErrorType? = nil
  
  private func done(error: ErrorType? = nil) {
    task?.cancel()
    self.error = error
    executing = false
    finished = true
  }

  weak var task: NSURLSessionTask?

  func request() {
    self.task?.cancel()
    
    self.task = session.dataTaskWithURL(url) {
      [weak self] data, response, error in
      if self?.cancelled == true {
        return
      }
      if let er = error {
        switch er.code {
        case NSURLErrorCancelled:
          return
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
          self?.check()
          return
        default:
          self?.done(er)
          return
        }
      }
      self?.done()
    }
    self.task?.resume()
  }
  
  override func start() {
    guard !cancelled else {
      return done()
    }
    executing = true
    request()
  }

  override func cancel() {
    done(ExampleError.Cancelled)
    super.cancel()
  }
}
//
//  Example.swift
//  example
//
//  Created by Michael Nisi on 29.12.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation
import Ola

enum ExampleError: Error {
  case cancelled
}

class Example: Operation {
  
  private let queue: DispatchQueue
  private let session: URLSession
  private let url: URL

  init(session: URLSession, url: URL, queue: DispatchQueue) {
    self.session = session
    self.url = url
    self.queue = queue
  }
  
  var allowsCellularAccess: Bool { get {
    return session.configuration.allowsCellularAccess }
  }
  
  func reachable(_ status: OlaStatus) -> Bool {
    switch status {
    case .reachable:
      return true
    case .cellular:
      return allowsCellularAccess
    case .unknown:
      return false
    }
  }
  
  lazy var ola: Ola? = { [unowned self] in
    Ola(host: self.url.host!, queue: self.queue)
  }()
  
  func check() {
    if let ola = self.ola {
      if reachable(ola.reach()) {
        request()
      } else {
        let ok = ola.reachWithCallback() { [weak self] status in
          if self?.isCancelled == false
            && self?.reachable(status) == true {
            self?.request()
          }
        }
        if !ok {
          fatalError("could not install callback")
        }
      }
    } else {
      fatalError("could not initialize")
    }
  }
  
  
  // Neither protected nor synchronized for brevity.
  var error: Error? = nil
  
  private func done(_ error: Error? = nil) {
    task?.cancel()
    self.error = error
    isExecuting = false
    isFinished = true
  }

  weak var task: URLSessionTask?

  func request() {
    self.task?.cancel()
    
    self.task = session.dataTask(with: url, completionHandler: {
      [weak self] data, response, error in
      if self?.isCancelled == true {
        return
      }
      if let er = error {
        switch er._code {
        case NSURLErrorCancelled:
          return
        case
        NSURLErrorTimedOut,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorNetworkConnectionLost:
          self?.check()
          return
        default:
          self?.done(er)
          return
        }
      }
      self?.done()
    }) 
    self.task?.resume()
  }
  
  // MARK: - Operation
  
  private var _executing: Bool = false
  
  override var isExecuting: Bool {
    get { return _executing }
    set {
      willChangeValue(forKey: "isExecuting")
      _executing = newValue
      didChangeValue(forKey: "isExecuting")
    }
  }
  
  private var _finished: Bool = false
  
  override var isFinished: Bool {
    get { return _finished }
    set {
      willChangeValue(forKey: "isFinished")
      _finished = newValue
      didChangeValue(forKey: "isFinished")
    }
  }
  
  override func start() {
    guard !isCancelled else {
      return done()
    }
    isExecuting = true
    request()
  }

  override func cancel() {
    done(ExampleError.cancelled)
    super.cancel()
  }
}

# Ola - check reachability of host

[![Swift 3](https://img.shields.io/badge/Swift-3.0-blue.svg)](https://swift.org/blog/swift-3-0-released/)
[![Platform](https://img.shields.io/badge/platforms-iOS-blue.svg)](https://developer.apple.com/discover/)

The **Ola** [Swift](https://swift.org/) module monitors reachability of a named host. It applies a callback when the reachability of the host changes. **Ola** is a simple Swift wrapper around some of Apple’s [System Configuration](https://developer.apple.com/reference/SystemConfiguration) APIs, making them easier to use.

## Example

This example shows how to use **Ola** in an asynchronous `Operation` to issue a bulletproof request, which, despite unreliable or no network connection, eventually succeeds, when the connection becomes available:

```swift
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
```

To try this you can put the example app, included in this repo, on your device and tap *Request*, executing the operation above, while taking a walk at the perimeter of your WLAN with disabled Mobile Data. Running the app in the simulator, try switching Wi-Fi on and off.

**Ola** doesn’t provide an `Operation` itself, because you’d already have one, encapuslating your request to transform reveived data, which is where you’d use **Ola**.

## Install

At this time, the Xcode projects in this repo only contain iOS targets. To use **Ola** in your iOS app: add `Ola.xcodeproj` to your workspace and link `Ola.framework` into your targets.

## License

[MIT](https://raw.github.com/michaelnisi/ola/master/LICENSE)

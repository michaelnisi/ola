# ola - check reachability of host

The **ola** [Swift](https://developer.apple.com/swift/) module monitors reachability of a named host. It applies a callback when the reachability of the host changes.

## Example

Issue a bulletproof request that, despite unreliable or no network connection, will eventually succeed, when the connection becomes available:

```swift
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
```

To try this, put the example app on your device and tap **Request**, executing the operation above, while taking a walk at the perimeter of your WLAN or fiddling with your network settings.

## Plumbing

To configure `module/module.map` for the C helpers wrapping the Swift callbacks, do:

```bash
$ ./configure
```

Add `Ola.xcodeproj` to your workspace to link with `Ola.framework` in your targets.

## License

[MIT License](https://raw.github.com/michaelnisi/ola/master/LICENSE)

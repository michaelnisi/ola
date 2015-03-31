
# ola - check reachability of host

The **ola** [Swift](https://developer.apple.com/swift/) module monitors the reachability of a named host. It applies a callback when the reachability of the host changes.

## Example

Issue a bulletproof request that—despite unreliable network—will eventually succeed:

```swift
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
```

To try this put the example app on your device and take a walk around the edges of connectivity (or fiddle with Settings).

## types

### OlaStatus

These constants represent the reachability status.

- `Unknown`
- `Reachable`
- `Cellular`

### Ola

An `Ola` object represents one reachability target.

## exports

The `Ola` class is the sole API of this framework.

### Creating an Ola object

```swift
init? (host: String, queue: dispatch_queue_t)
```
Initializes an `Ola` instance to monitor reachability of the target host.

- `host` The name of the host
- `queue` The queue to schedule the callbacks

Returns newly initialized `Ola` object or `nil`, if the host could not be scheduled.

### Checking reachability

```swift
reach () -> OlaStatus
```
Checks the reachability of the host.

Returns `OlaStatus`.

### Monitoring reachability

```swift
reachWithCallback (cb: (OlaStatus) -> Void) -> Bool
```
Installs the callback to be applied when the reachability of the host changes. The monitoring stops when the given `Ola` object deinitializes.

- `cb` The callback to apply on reachability changes.

Returns `true` if the callback has been successfully installed.

## Install

To configure the [private module map file](http://clang.llvm.org/docs/Modules.html#private-module-map-files) `module/module.map` do:

```bash
$ ./configure
```
And add `Ola.xcodeproj` to your workspace to link with `Ola.framework` in your targets.

## License

MIT


# ola - check reachability of host

The **ola** [Swift](https://developer.apple.com/swift/) module monitors the reachability of a named host. It applies a callback each time the reachability of the host changes.

## Example

Issue a bulletproof request that, despite unreliable network, will eventually succeed.

```swift
import Foundation
import Ola

public class Example: NSOperation {
  let session: NSURLSession
  let url: NSURL
  let queue: dispatch_queue_t
  let sema = dispatch_semaphore_create(0)

  weak var task: NSURLSessionTask?
  var ola: Ola?

  public init (session: NSURLSession, url: NSURL, queue: dispatch_queue_t) {
    self.session = session
    self.url = url
    self.queue = queue
  }

  func request () {
    let sema = self.sema
    task = session.dataTaskWithURL(url) { data, response, error in
      if self.cancelled { return }
      if error != nil {
        self.check()
      } else {
        dispatch_semaphore_signal(sema)
      }
    }
    task?.resume()
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
    if cancelled { return }
    request()
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
  }

  public override func cancel () {
    task?.cancel()
    dispatch_semaphore_signal(sema)
    super.cancel()
  }
}
```

To try this put the example app on your device and take a walk around the edges of connectivity (or toggle Wi-Fi).

## types

### OlaStatus

These constants represent the reachability status.

- `Unknown`
- `Reachable`
- `ConnectionRequired`

### Ola

An `Ola` object represents one reachibility target.

## exports

The `Ola` class is the sole API of this framework.

### Creating an Ola object

```swift
init (host: String, queue: dispatch_queue_t)
```
Initializes an `Ola` instance to monitor reachability of the target host.

- `host` The name of the host
- `queue` The queue to schedule the callbacks

Returns newly initialized `Ola` object.

### Monitoring reachability

```swift
reachWithCallback (cb: (OlaStatus) -> Void) -> Bool
```
Installs the callback to be applied when the reachability of the host changes. The monitoring stops when the given `Ola` object deinitializes.

- `cb` The callback to apply on reachability changes.

Returns `true`, if the callback has been successfully installed.

## Install

To install do:

```bash
$ ./configure
$ xcodebuild -configuration Debug build
```
This generates the private module map `module/module.map` and builds an iOS framework with debug configuration. Accordingly you can add `Ola.xcodeproj` to your workspace and link with `Ola.framework` in your targets.

## License

MIT

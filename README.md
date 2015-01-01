
# ola - check reachability of host

The **ola** [Swift](https://developer.apple.com/swift/) module can be used to monitor the reachability of a named host. It applies a user callback on reachability changes.

## Example

```swift
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
```

## Install

To install do:

```bash
$ ./configure
$ xcodebuild -configuration Debug build
```
This generates the private module map `module/module.map` and builds an iOS framework with debug configuration. Accordingly you can add `Ola.xcodeproj` to your workspace and link with `Ola.framework` in your targets.

## License

MIT

# Ola - check reachability of host

The **Ola** [Swift](https://swift.org/) module lets you check network reachability of a named host. You can set a callback to run when the reachability of the host has changed. **Ola** is a simple Swift wrapper around some of Apple’s [System Configuration](https://developer.apple.com/reference/SystemConfiguration) APIs, making them easier to use.

## Example

```swift
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
    assert(Thread.isMainThread)

    func done() {
      DispatchQueue.main.async {
        self.task = nil
        sender.selectedSegmentIndex = 1
      }
    }

    let url = URL(string: "https://apple.com/")!

    func check() {
      self.task = nil

      guard let p = Ola(host: url.host!) else {
        return done()
      }

      self.probe = p

      // Simply checking if the host is reachable is the common use case.
      let status = p.reach()

      guard (status == .cellular || status == .reachable) else {
        // Unreachable host, installing a callback.
        let ok = p.install { status in
          guard (status == .cellular || status == .reachable) else {
            // Status changed, but host still isn’t reachable, keep waiting.
            return
          }
          // Host supposedly reachable, try again.
          DispatchQueue.main.async {
            self.probe = nil
            self.valueChanged(sender)
          }
        }
        guard ok else {
          // Installing the callback failed.
          return done()
        }
        // Awaiting reachability changes.
        return
      }

      valueChanged(sender)
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
            return check()
          default:
            return done()
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
```

Find this example in `./example`.

## Types

```swift
enum OlaStatus: Int
```

`OlaStatus` eumerates three basic host states—a boiled down version of [SCNetworkReachabilityFlags](https://developer.apple.com/documentation/systemconfiguration/scnetworkreachabilityflags) in [SystemConfiguration](https://developer.apple.com/documentation/systemconfiguration).

- `unknown`
- `reachable`
- `cellular`

```swift
class Ola: Reaching
```

`Ola` is the main object of this module, it implements the tiny `Reaching` API:

```swift
protocol Reaching {
  func reach() -> OlaStatus
  func install(callback: @escaping (OlaStatus) -> Void) -> Bool
}
```

## Exports

### Creating a Probe

Each `Ola` object is dedicated to monitoring a specific host. Monitoring stop when the `Ola` object gets deallocated.

```swift
init?(host: String)
```

- `host` The name of the host to monitor.

### Checking Host Reachability

The common use case is to synchronously check if a given host is reachable.

```swift
func reach() -> OlaStatus
```

Returns the reachability of the host: unknown, reachable, or cellular.

### Monitoring Host

A less common use case is getting notified, when the state of a given host has changed. For example, to reason if it’s appropiate to issue a request.

```swift
func install(callback: @escaping (OlaStatus) -> Void) -> Bool
```

Returns `true` if installing the `callback` has been successful. The callback gets removed, of course, when its `Ola` object is deinitializing.

## Install

At this time, the Xcode projects in this repo only contain iOS targets. To use **Ola** in your iOS app: add `Ola.xcodeproj` to your workspace and link `Ola.framework` into your targets.

## License

[MIT](https://raw.github.com/michaelnisi/ola/master/LICENSE)

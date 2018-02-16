# Ola - check reachability of host

The **Ola** [Swift](https://swift.org/) module monitors reachability of a named host. It applies a callback when the reachability of the host changes. **Ola** is a simple Swift wrapper around some of Apple’s [System Configuration](https://developer.apple.com/reference/SystemConfiguration) APIs, making them easier to use.

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
        sender.selectedSegmentIndex = 1
      }
    }

    let url = URL(string: "https://apple.com/")!

    func check() {
      guard let p = Ola(host: url.host!) else {
        return done()
      }

      self.probe = p

      let status = p.reach()
      guard (status == .cellular || status == .reachable) else {
        let ok = p.reach { status in
          guard (status == .cellular || status == .reachable) else {
            return
          }
          DispatchQueue.main.async {
            self.valueChanged(sender)
          }
        }
        guard ok else {
          return done()
        }
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

## Install

At this time, the Xcode projects in this repo only contain iOS targets. To use **Ola** in your iOS app: add `Ola.xcodeproj` to your workspace and link `Ola.framework` into your targets.

## License

[MIT](https://raw.github.com/michaelnisi/ola/master/LICENSE)

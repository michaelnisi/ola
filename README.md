# Ola - check reachability of host

The **Ola** [Swift](https://swift.org/) module lets you check network reachability of a named host. You can set a callback to run when the reachability of the host has changed. **Ola** is a simple Swift wrapper around some of Apple’s [System Configuration](https://developer.apple.com/reference/SystemConfiguration) APIs, making them easier to use.

## Example

```swift
import Foundation
import os.log

let host = "apple.com"
var probe = Ola(host: host, log: .default)

probe?.activate { status in
  print("host status: (\(host), \(String(describing: status)))")
}

sleep(10)

probe?.invalidate()
probe = nil

print("OK")
```

## Types

```swift
enum OlaStatus: Int
```

`OlaStatus` eumerates three boiled down host states, derived from [SCNetworkReachabilityFlags](https://developer.apple.com/documentation/systemconfiguration/scnetworkreachabilityflags).

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
  func reach(statusBlock: @escaping (OlaStatus) -> Void)
  func activate(installing callback: @escaping (OlaStatus) -> Void) -> Bool
  func invalidate()
}
```

## Exports

### Creating a Probe

Each `Ola` object is dedicated to monitoring a specific host.

```swift
init?(host: String, log: OSLog?)
```

- `host` The name of the host to monitor.

### Checking Host Reachability

The common use case is to synchronously—not on the main thread though [QA1693](https://developer.apple.com/library/content/qa/qa1693/_index.html)—check if a given host is reachable.

```swift
func reach() -> OlaStatus
```

Returns the reachability of the host: unknown, reachable, or cellular.

```swift
func reach(statusBlock: @escaping (OlaStatus) -> Void)
```

Same as `reach()`, but non-blocking, executing on a system-provided global concurrent dispatch queues.

### Monitoring Host

A less common use case is getting notified, when the state of a given host has changed. For example, to reason if it’s appropiate to issue a request.

```swift
func activate(installing callback: @escaping (OlaStatus) -> Void) -> Bool
```

Returns `true` if installing the `callback` has been successful.

```swift
func invalidate()
```

Invalidates the probe removing the callback.

## Install

Add `https://github.com/michaelnisi/ola` to your package manifest.

## License

[MIT](https://raw.github.com/michaelnisi/ola/master/LICENSE)

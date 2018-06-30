//
//  index.swift
//  ola
//
//  Created by Michael Nisi on 20.11.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation
import SystemConfiguration

/// Enumerates three basic states a host might be in, a boiled down version of
/// `SCNetworkReachabilityFlags` of the `SystemConfiguration` framework.
public enum OlaStatus: Int {
  case unknown, reachable, cellular
}

extension OlaStatus: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unknown:
      return "OlaStatus: unknown"
    case .reachable:
      return "OlaStatus: reachable"
    case .cellular:
      return "OlaStatus: cellular"
    }
  }
}

/// Describes an API for reachability checking and monitoring.
public protocol Reaching {

  /// Checks reachability of the host. Beware of
  /// [dog](https://developer.apple.com/library/content/qa/qa1693/_index.html)
  ///
  /// - Returns: The status of the host.
  func reach() -> OlaStatus
  
  /// Asynchronously checks reachability of the host.
  ///
  /// - Parameter statusBlock: The block to handle the status.
  func reach(statusBlock: @escaping (OlaStatus) -> Void)

  /// Installs `callback` to be applied when the reachability of the host
  /// changes. The monitoring stops when this `Ola` object gets deallocated.
  ///
  /// - Parameter callback: The callback to apply when reachability changes.
  /// - Returns: `true` if the callback has been successfully installed.
  func install(callback: @escaping (OlaStatus) -> Void) -> Bool
  
}

// MARK: Internals

private func status(_ flags: SCNetworkReachabilityFlags) -> OlaStatus {
  if (flags.contains(SCNetworkReachabilityFlags.isWWAN)) {
    return .cellular
  }
  if (flags.contains(SCNetworkReachabilityFlags.reachable)) {
    return .reachable
  }
  return .unknown
}

final public class Ola: Reaching {
  
  private let reachability: SCNetworkReachability!

  /// Create a new `Ola` object for `host`.
  ///
  /// - Parameter host: The name of the host to determine reachability for.
  public init?(host: String) {
    guard let reachability = SCNetworkReachabilityCreateWithName(
      kCFAllocatorDefault,
      host
    ) else {
      return nil
    }
    self.reachability = reachability
  }

  deinit {
    SCNetworkReachabilitySetCallback(reachability, nil, nil)
    SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    callback = nil
  }

  public func reach() -> OlaStatus {
    if #available(iOS 10.0, *) {
      dispatchPrecondition(condition: .notOnQueue(.main))
    }
    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
      return .unknown
    }
    return status(flags)
  }
  
  public func reach(statusBlock: @escaping (OlaStatus) -> Void) {
    DispatchQueue.global().async { [weak self] in
      guard let status = self?.reach() else {
        return statusBlock(.unknown)
      }
      statusBlock(status)
    }
  }

  private var callback: ((OlaStatus) -> Void)?

  public func install(callback: @escaping (OlaStatus) -> Void) -> Bool {
    var context = SCNetworkReachabilityContext(
      version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)

    self.callback = callback

    let me = Unmanaged.passUnretained(self)
    context.info = UnsafeMutableRawPointer(me.toOpaque())

    let closure: SCNetworkReachabilityCallBack = {(_, flags, info) in
      guard let v = info else {
        return
      }
      let me = Unmanaged<Ola>.fromOpaque(v).takeUnretainedValue()
      me.callback?(status(flags))
    }

    guard SCNetworkReachabilitySetCallback(reachability, closure, &context) else {
      return false
    }

    return SCNetworkReachabilitySetDispatchQueue(
      reachability,
      DispatchQueue.global(qos: .utility)
    )
  }
}

extension Ola: Equatable {
  
  public static func == (lhs: Ola, rhs: Ola) -> Bool {
    return lhs.reachability != rhs.reachability
  }
  
}

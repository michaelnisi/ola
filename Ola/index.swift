//
//  index.swift
//  ola
//
//  Created by Michael Nisi on 20.11.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation
import SystemConfiguration
import ola_helpers

// MARK: API

/// Enumerates the three possible statuses a host can have—a simplified
/// interpretation of `SCNetworkReachabilityFlags`.
public enum OlaStatus: Int {
  case Unknown, Reachable, Cellular
}

extension OlaStatus: CustomStringConvertible {
  static let desc = [
    0: "OlaStatus: unknown",
    1: "OlaStatus: reachable",
    2: "OlaStatus: cellular"
  ]
  public var description: String {
    return OlaStatus.desc[self.rawValue]!
  }
}

/// A minimal API for reachability checking and monitoring.
public protocol Reaching {
  func reach() -> OlaStatus
  func reachWithCallback(cb: (OlaStatus) -> Void) -> Bool
}

// MARK: -

private func status(flags: SCNetworkReachabilityFlags) -> OlaStatus {
  if (flags.contains(SCNetworkReachabilityFlags.IsWWAN)) {
    return .Cellular
  }
  if (flags.contains(SCNetworkReachabilityFlags.Reachable)) {
    return .Reachable
  }
  return .Unknown
}

final public class Ola: Reaching {
  let target: SCNetworkReachability!
  let queue: dispatch_queue_t
  
  // MARK: Creating an Ola object

  /// Initializes an `Ola` instance to monitor reachability of the target host.
  ///
  /// - parameter host: The name of the target host.
  /// - parameter queue: The queue to schedule the callbacks.
  public init?(host: String, queue: dispatch_queue_t) {
    self.queue = queue
    guard let target = SCNetworkReachabilityCreateWithName(
      kCFAllocatorDefault,
      host
    ) else {
      return nil
    }
    guard SCNetworkReachabilitySetDispatchQueue(target, queue) else {
      return nil
    }
    self.target = target
  }

  deinit {
    ola_set_callback(target, nil)
    SCNetworkReachabilitySetDispatchQueue(target, nil)
  }
  
  // MARK: Checking reachability

  /// Checks the reachability of the host.
  ///
  /// - returns: The status of the host.
  public func reach() -> OlaStatus {
    var flags = SCNetworkReachabilityFlags()
    if SCNetworkReachabilityGetFlags(target, &flags) {
      return status(flags)
    } else {
      return .Unknown
    }
  }
  
  // MARK: Monitoring reachability

  /// Installs the callback to be applied when the reachability of the host 
  /// changes. The monitoring stops when the given `Ola` object deinitializes.
  /// 
  /// - parameter cb: The callback to apply when reachability changes.
  /// - returns: `true` if the callback has been successfully installed.
  public func reachWithCallback(cb: (OlaStatus) -> Void) -> Bool {
    unowned let q = queue
    return ola_set_callback(target, { flags in
      dispatch_async(q) { cb(status(flags)) }
    })
  }
}

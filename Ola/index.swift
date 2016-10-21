//
//  index.swift
//  ola
//
//  Created by Michael Nisi on 20.11.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation
import SystemConfiguration

// MARK: API

/// Enumerates the three basic states host might be in—a boiled down version of
/// `SCNetworkReachabilityFlags` in the `SystemConfiguration` framework.
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
  func reach() -> OlaStatus
  func reachWithCallback(_ cb: @escaping (OlaStatus) -> Void) -> Bool
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
  private let queue: DispatchQueue
  private var cb: ((OlaStatus) -> Void)! = nil

  /// Create a new `Ola` object for the specifified host.
  ///
  /// - parameter host: The name of the host to determine reachability for.
  /// - parameter queue: The queue to schedule callbacks on.
  public init?(host: String, queue: DispatchQueue) {
    self.queue = queue
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
  }

  /// Checks the reachability of the host.
  ///
  /// - returns: The status of the host.
  public func reach() -> OlaStatus {
    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
      return .unknown
    }
    return status(flags)
  }

  /// Installs the callback to be applied when the reachability of the host 
  /// changes. The monitoring stops when the given `Ola` object deinitializes.
  /// 
  /// - parameter cb: The callback to apply when reachability changes.
  /// - returns: `true` if the callback has been successfully installed.
  public func reachWithCallback(_ cb: @escaping (OlaStatus) -> Void) -> Bool {
    var context = SCNetworkReachabilityContext(
      version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
    
    self.cb = cb

    let me = Unmanaged.passUnretained(self)
    let info = UnsafeMutableRawPointer(me.toOpaque())
    
    context.info = info
    
    let closure: SCNetworkReachabilityCallBack = {(_, flags, info) in
      let me = Unmanaged<Ola>.fromOpaque(info!).takeUnretainedValue()
      me.queue.sync {
        me.cb(status(flags))
      }
    }
    
    guard SCNetworkReachabilitySetCallback(reachability, closure, &context) else {
      return false
    }
    
    return SCNetworkReachabilitySetDispatchQueue(reachability, DispatchQueue.main)
  }
}

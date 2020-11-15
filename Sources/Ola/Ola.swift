//
//  index.swift
//  ola
//
//  Created by Michael Nisi on 20.11.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation
import SystemConfiguration
import os.log

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

  /// Checks reachability of the host. Executing this on the main queue traps.
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
  /// If installing the callback failed and this returns `false`, you should
  /// invalidate this probe and replace it.
  ///
  /// - Parameter callback: The callback to apply when reachability changes.
  /// - Returns: `true` if the callback has been successfully installed.
  @discardableResult
  func activate(installing callback: @escaping (OlaStatus) -> Void) -> Bool
  
  /// Invalidates this probe, removing the callback, preparing to `deinit`.
  func invalidate()

}

// MARK: Internals

private func makeStatus(_ flags: SCNetworkReachabilityFlags) -> OlaStatus {
  #if os(iOS)
  if (flags.contains(.isWWAN)) {
    return .cellular
  }
  #endif
  if (flags.contains(.reachable)) {
    return .reachable
  }
  return .unknown
}

final public class Ola: Reaching {

  private let host: String
  private let log: OSLog
  
  private let reachability: SCNetworkReachability

  /// Create a new `Ola` object for `host`.
  ///
  /// - Parameters:
  ///   - host: The name of the host to determine reachability for.
  ///   - log: The log object to use for logging.
  public init?(host: String, log: OSLog = .disabled) {
    os_log("creating reachability: %@", log: log, type: .info, host)

    guard let reachability = SCNetworkReachabilityCreateWithName(
      kCFAllocatorDefault,
      host
    ) else {
      return nil
    }
    
    self.host = host
    self.log = log
    
    self.reachability = reachability
  }

  deinit {
    os_log("deinit", log: log, type: .info)
  }

  public func reach() -> OlaStatus {
    dispatchPrecondition(condition: .notOnQueue(.main))
    
    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
      return .unknown
    }
    return makeStatus(flags)
  }

  public func reach(statusBlock: @escaping (OlaStatus) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let status = self?.reach() else {
        return statusBlock(.unknown)
      }
      statusBlock(status)
    }
  }

  private var callback: ((OlaStatus) -> Void)?
  
  private (set) var status = OlaStatus.unknown {
    didSet {
      guard status != oldValue else {
        return
      }
      callback?(status)
    }
  }

  @discardableResult
  public func activate(installing callback: @escaping (OlaStatus) -> Void) -> Bool {
    guard self.callback == nil else {
      os_log("not installing: callback already set", log: log)
      return false
    }

    os_log("installing callback", log: log, type: .info)
    
    var context = SCNetworkReachabilityContext(
      version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)

    self.callback = callback

    let ptr = Unmanaged.passRetained(self).toOpaque()
    context.info = UnsafeMutableRawPointer(ptr)
    context.release = {
      Unmanaged<Ola>.fromOpaque($0).release()
    } as @convention(c) (UnsafeRawPointer) -> Void

    guard SCNetworkReachabilitySetCallback(reachability, {(_, flags, info) in
      guard let ptr = info else {
        return
      }
      let me = Unmanaged<Ola>.fromOpaque(ptr).takeUnretainedValue()
      me.status = makeStatus(flags)
    } , &context) else {
      return false
    }

    return SCNetworkReachabilitySetDispatchQueue(
      reachability, .global(qos: .utility))
  }

  public func invalidate() {
    os_log("invalidating", log: log, type: .info)

    callback = nil
    
    SCNetworkReachabilitySetCallback(reachability, nil, nil)
    SCNetworkReachabilitySetDispatchQueue(reachability, nil)
  }

}

extension Ola: Equatable {

  public static func == (lhs: Ola, rhs: Ola) -> Bool {
    return lhs.reachability != rhs.reachability
  }

}

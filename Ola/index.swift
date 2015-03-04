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

public enum OlaStatus: Int {
  case Unknown, Reachable, Cellular
}

extension OlaStatus: Printable {
  static let desc = [
    0: "unkown"
  , 1: "reachable"
  , 2: "cellular"
  ]
  public var description: String {
    return OlaStatus.desc[self.rawValue]!
  }
}

func status (flags: SCNetworkReachabilityFlags) -> OlaStatus {
  if (flags & SCNetworkReachabilityFlags(
    kSCNetworkReachabilityFlagsIsWWAN) != 0) {
    return .Cellular
  }
  if (flags & SCNetworkReachabilityFlags(
    kSCNetworkReachabilityFlagsReachable) != 0) {
    return .Reachable
  }
  return .Unknown
}

public class Ola {
  let target: SCNetworkReachability
  let queue: dispatch_queue_t

  public init? (host: String, queue: dispatch_queue_t) {
    self.queue = queue
    let ref = SCNetworkReachabilityCreateWithName(
      kCFAllocatorDefault, host)
    target = ref.takeRetainedValue()
    if SCNetworkReachabilitySetDispatchQueue(target, queue) != 1 {
      return nil
    }
  }

  deinit {
    ola_set_callback(target, nil)
    SCNetworkReachabilitySetDispatchQueue(target, nil)
  }

  public func reach () -> OlaStatus {
    var flags: SCNetworkReachabilityFlags = 0
    let ok = SCNetworkReachabilityGetFlags(target, &flags)
    return ok == 1 ? status(flags) : .Unknown
  }

  public func reachWithCallback (cb: (OlaStatus) -> Void) -> Bool {
    unowned let q = queue
    return ola_set_callback(target, { flags in
      dispatch_async(q) { cb(status(flags)) }
    }) != 0
  }
}

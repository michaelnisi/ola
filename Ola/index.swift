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
  case Unknown, Reachable, ConnectionRequired
}

public class Ola {
  let target: SCNetworkReachability
  let queue: dispatch_queue_t

  public init (host: String, queue: dispatch_queue_t) {
    self.queue = queue
    let ref = SCNetworkReachabilityCreateWithName(
      kCFAllocatorDefault, host)
    target = ref.takeRetainedValue()
    SCNetworkReachabilitySetDispatchQueue(target, queue)
  }

  deinit {
    ola_set_callback(target, nil)
    SCNetworkReachabilitySetDispatchQueue(target, nil)
  }

  public func reachWithCallback (cb: (OlaStatus) -> Void) -> Bool {
    func status (flags: SCNetworkReachabilityFlags) -> OlaStatus {
      if (flags & SCNetworkReachabilityFlags(
        kSCNetworkReachabilityFlagsConnectionRequired) != 0) {
          return .ConnectionRequired
      }
      if (flags & SCNetworkReachabilityFlags(
        kSCNetworkReachabilityFlagsReachable) != 0) {
        return .Reachable
      }
      return .Unknown
    }
    unowned let q = queue
    return ola_set_callback(target, { flags in
      dispatch_async(q) { cb(status(flags)) }
    }) != 0
  }
}

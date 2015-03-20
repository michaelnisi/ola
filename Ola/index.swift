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
    0: "OlaStatus: unkown"
  , 1: "OlaStatus: reachable"
  , 2: "OlaStatus: cellular"
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

private func ok (value: Boolean) -> Bool {
  return value == 1
}

public class Ola {
  let target: SCNetworkReachability!
  let queue: dispatch_queue_t

  public init? (host h: String?, queue: dispatch_queue_t) {
    self.queue = queue
    if let host = h {
      let ref = SCNetworkReachabilityCreateWithName(
        kCFAllocatorDefault, host)
      target = ref.takeRetainedValue()
      if !ok(SCNetworkReachabilitySetDispatchQueue(target, queue)) {
        return nil
      }
    } else {
      return nil
    }
  }

  deinit {
    ola_set_callback(target, nil)
    SCNetworkReachabilitySetDispatchQueue(target, nil)
  }

  public func reach () -> OlaStatus {
    var flags: SCNetworkReachabilityFlags = 0
    if ok(SCNetworkReachabilityGetFlags(target, &flags)) {
      return status(flags)
    } else {
      return .Unknown
    }
  }

  public func reachWithCallback (cb: (OlaStatus) -> Void) -> Bool {
    unowned let q = queue
    return ola_set_callback(target, { flags in
      dispatch_async(q) { cb(status(flags)) }
    }) != 0
  }
}

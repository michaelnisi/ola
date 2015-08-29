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

extension OlaStatus: CustomStringConvertible {
  static let desc = [
    0: "OlaStatus: unkown",
    1: "OlaStatus: reachable",
    2: "OlaStatus: cellular"
  ]
  public var description: String {
    return OlaStatus.desc[self.rawValue]!
  }
}

func status (flags: SCNetworkReachabilityFlags) -> OlaStatus {
  if (flags.contains(SCNetworkReachabilityFlags.IsWWAN)) { return .Cellular }
  if (flags.contains(SCNetworkReachabilityFlags.Reachable)) { return .Reachable }
  return .Unknown
}

public class Ola {
  let target: SCNetworkReachability!
  let queue: dispatch_queue_t

  public init? (host: String, queue: dispatch_queue_t) {
    self.queue = queue
    target = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host)
    if target == nil { return nil }
    guard SCNetworkReachabilitySetDispatchQueue(target, queue) else { return nil }
  }

  deinit {
    ola_set_callback(target, nil)
    SCNetworkReachabilitySetDispatchQueue(target, nil)
  }

  public func reach () -> OlaStatus {
    var flags = SCNetworkReachabilityFlags()
    if SCNetworkReachabilityGetFlags(target, &flags) {
      return status(flags)
    } else {
      return .Unknown
    }
  }

  public func reachWithCallback (cb: (OlaStatus) -> Void) -> Bool {
    unowned let q = queue
    return ola_set_callback(target, { flags in
      dispatch_async(q) { cb(status(flags)) }
    })
  }
}

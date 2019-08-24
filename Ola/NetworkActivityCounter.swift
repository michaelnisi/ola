//
//  NetworkActivityCounter.swift
//  Ola
//
//  Created by Michael Nisi on 4/30/18.
//  Copyright © 2018 Michael Nisi. All rights reserved.
//

import Foundation
import os.log

private let log = OSLog.disabled

/// Maintains the visibility of the network activity indicator.
public class NetworkActivityCounter {
  
  private init() {}
  
  public static let shared = NetworkActivityCounter()
  
  /// This block executes on the main queue when this counter is modified
  /// receiving `true` while the counter is not zero.
  ///
  /// Use `increase`, `decrease`, or `reset` to signal network activity. The 
  /// default closure displayes a spinning indicator in the status bar that 
  /// shows network activity. This indicator has been deprecated with iOS 13.
  public var isNetworkActivityBlock: ((Bool) -> Void)? = { active in
    UIApplication.shared.isNetworkActivityIndicatorVisible = active
  }
  
  private let sQueue = DispatchQueue(
    label: "ink.codes.ola.NetworkActivityCounter",
    target: .global(qos: .userInteractive)
  )
  
  private var _count = 0
  
  private(set) var count: Int {
    get { return sQueue.sync { _count } }
    
    set {
      sQueue.sync {
        if #available(iOS 10.0, *), newValue < 0 {
          os_log("NetworkActivityCounter: unbalanced attempt to remove", log: log)
        }
        
        _count = max(0, newValue)
        let v = _count != 0
        
        DispatchQueue.main.async { [weak self] in
          self?.isNetworkActivityBlock?(v)
        }
      }
    }
  }
}

extension NetworkActivityCounter {
  
  public func increase() {
    count = count + 1
  }
  
  public func decrease() {
    count = count - 1
  }
  
  public func reset() {
    count = 0
  }
}

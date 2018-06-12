//
//  NetworkActivityCounter.swift
//  Ola
//
//  Created by Michael Nisi on 4/30/18.
//  Copyright © 2018 Michael Nisi. All rights reserved.
//

import Foundation
import os.log

/// Maintains the visibility of the network activity indicator.
public class NetworkActivityCounter {
  
  private init() {}
  
  public static let shared = NetworkActivityCounter()
  
  private let sQueue = DispatchQueue(
    label: "ink.codes.ola.NetworkActivityCounter")
  
  private var _count = 0
  
  private(set) var count: Int {
    get {
      return sQueue.sync {
        return _count
      }
    }
    
    set {
      sQueue.sync {
        if #available(iOS 10.0, *), newValue < 0 {
          os_log("NetworkActivityCounter: unbalanced attempt to remove")
        }
        _count = max(0, newValue)
        let v = _count != 0
        DispatchQueue.main.async {
          UIApplication.shared.isNetworkActivityIndicatorVisible = v
        }
      }
    }
  }
  
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

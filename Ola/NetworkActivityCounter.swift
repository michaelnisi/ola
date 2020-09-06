//
//  NetworkActivityCounter.swift
//  Ola
//
//  Created by Michael Nisi on 4/30/18.
//  Copyright © 2018 Michael Nisi. All rights reserved.
//

import Foundation
import Combine

public class NetworkActivityCounter {

  private let subject = CurrentValueSubject<Int, Never>(0)
  
  private init() {}

  // MARK: - API

  public static let shared = NetworkActivityCounter()

  public var isActive: AnyPublisher<Bool, Never>  {
    subject.map { $0 > 0 }.eraseToAnyPublisher()
  }

  public func increase() {
    subject.value = subject.value + 1
  }

  public func decrease() {
    subject.value = max(0, subject.value - 1)
  }

  public func reset() {
    subject.value = 0
  }
}

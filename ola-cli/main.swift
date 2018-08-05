//
//  main.swift
//  ola-cli
//
//  Created by Michael Nisi on 8/5/18.
//  Copyright © 2018 Michael Nisi. All rights reserved.
//

import Foundation

let host = "apple.com"
var probe = Ola(host: host)

probe?.activate { status in
  print("host status: (\(host), \(String(describing: status)))")
}

sleep(10)
probe?.invalidate()
probe = nil
sleep(5)

print("OK")


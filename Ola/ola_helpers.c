//
//  ola_helpers.c
//  ola
//
//  Created by Michael Nisi on 21.11.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

#include "ola_helpers.h"

static void ola_callback(SCNetworkReachabilityRef clone,
                         SCNetworkReachabilityFlags cloneFlags,
                         void *info) {
  if (info) {
    int (^cb)(SCNetworkReachabilityFlags) = info;
    cb(cloneFlags);
  }
}

Boolean ola_set_callback(SCNetworkReachabilityRef target, ola_closure cb) {
  void *retain = _Block_copy;
  SCNetworkReachabilityContext context = {
    0, cb, retain, _Block_release, NULL
  };
  return SCNetworkReachabilitySetCallback(target, ola_callback, &context);
}
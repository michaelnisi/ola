//
//  ola_helpers.h
//  ola
//
//  Created by Michael Nisi on 21.11.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

#ifndef __ola__ola_helpers__
#define __ola__ola_helpers__

#import <SystemConfiguration/SystemConfiguration.h>

Boolean
ola_set_callback(
  SCNetworkReachabilityRef target
, void(^cb)(SCNetworkReachabilityFlags));

#endif /* defined(__ola__ola_helpers__) */

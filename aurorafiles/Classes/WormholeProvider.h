//
//  WormholeProvider.h
//  aurorafiles
//
//  Created by Slava Kutenkov on 04/07/2017.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//


#import "MMWormhole.h"

typedef NSString *const AUWormholeNotificationName NS_EXTENSIBLE_STRING_ENUM;
FOUNDATION_EXPORT AUWormholeNotificationName const AUWormholeNotificationUserSignIn;
FOUNDATION_EXPORT AUWormholeNotificationName const AUWormholeNotificationUserSignOut;

@interface WormholeProvider : NSObject



+ (WormholeProvider *)instance;
- (void)sendNotification:(AUWormholeNotificationName)notificationName object:(id)object;
- (void)catchNotification:(AUWormholeNotificationName)notificationName handler:(nullable void (^)(__nullable id messageObject))handler;
- (void)stopObservingNotification:(AUWormholeNotificationName)notificationName;
- (void)cancelObservingNotification:(AUWormholeNotificationName)notificationName;

@end

//
//  WormholeProvider.m
//  aurorafiles
//
//  Created by Slava Kutenkov on 04/07/2017.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//

#import "WormholeProvider.h"



AUWormholeNotificationName AUWormholeNotificationUserSignIn = @"logInAction";
AUWormholeNotificationName AUWormholeNotificationUserSignOut = @"logOutAction";

static NSString* appGroupID = @"group.afterlogic.aurorafiles";
static NSString* wormholeDirectory = @"wormhole";

@interface WormholeProvider(){

}
@property (nonatomic) MMWormhole *wormhole;

@end
@implementation WormholeProvider
+ (WormholeProvider *)instance {
    static WormholeProvider *_instance = nil;
    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] initWormhole];
        }
    }
    return _instance;
}

- (instancetype)initWormhole{
    self = [super init];
    if (self) {
        self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:appGroupID
                                                             optionalDirectory:wormholeDirectory];

    }

    return self;
}

- (void)sendNotification:(AUWormholeNotificationName)notificationName object:(id)object {
    [self.wormhole passMessageObject:object identifier:notificationName];
}

- (void)catchNotification:(AUWormholeNotificationName)notificationName handler:(nullable void (^)(__nullable id messageObject))handler{
    [self.wormhole listenForMessageWithIdentifier:notificationName listener:handler];
}

- (void)stopObservingNotification:(AUWormholeNotificationName)notificationName{
    [self.wormhole stopListeningForMessageWithIdentifier:notificationName];
}

- (void)cancelObservingNotification:(AUWormholeNotificationName)notificationName{
    [self.wormhole clearMessageContentsForIdentifier:notificationName];
}
@end

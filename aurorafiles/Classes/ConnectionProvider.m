//
//  ConnectionProvider.m
//  aurorafiles
//
//  Created by Cheshire on 05.08.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//
#import "Constants.h"
#import "ConnectionProvider.h"
#import <BugfenderSDK/BugfenderSDK.h>

@interface ConnectionProvider () {
    Reachability* reach;
//    BOOL _isOnline;
}

@property (assign,nonatomic) BOOL _isOnline;

@end

@implementation ConnectionProvider
@synthesize _isOnline;

+ (instancetype) sharedInstance
{
    static ConnectionProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ConnectionProvider alloc] init];
    });
    return sharedInstance;
}

-(void)startNotification{
    // Allocate a reachability object
    reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    // Tell the reachability that we DON'T want to be reachable on 3G/EDGE/CDMA
    reach.reachableOnWWAN = YES;
    
    // Here we set up a NSNotification observer. The Reachability that caused the notification
    // is passed in the object parameter
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    _isOnline = NO;
    
    [reach startNotifier];
}

-(void)stopNotification{
    [reach stopNotifier];
}

-(void)reachabilityChanged:(NSNotification *)notify{
//    NSLog(@"sender is -> %@", notify);
    if ([notify.object isKindOfClass:[Reachability class]]) {
        Reachability* tmpReach = notify.object;
        NetworkStatus status = [tmpReach currentReachabilityStatus];
        switch (status) {
            case ReachableViaWiFi:
            case ReachableViaWWAN:{
//                if (!_isOnline) {
//                    _isOnline = YES;
                [[NSNotificationCenter defaultCenter]postNotificationName:CPNotificationConnectionOnline object:nil];
//                BFLog(@"");
//                }
            }
                break;
                
            default:{
//                _isOnline = NO;
                [[NSNotificationCenter defaultCenter]postNotificationName:CPNotificationConnectionLost object:nil];
                BFLog(@"connection lost");
                
            }
                break;
        }
    }
}

@end

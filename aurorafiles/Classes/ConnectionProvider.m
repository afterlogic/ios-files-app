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
    reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableOnWWAN = YES;
    
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
    if ([notify.object isKindOfClass:[Reachability class]]) {
        Reachability* tmpReach = notify.object;
        NetworkStatus status = [tmpReach currentReachabilityStatus];
        switch (status) {
            case ReachableViaWiFi:
            case ReachableViaWWAN:{
                    if (!_isOnline) {
                        [[NSNotificationCenter defaultCenter]postNotificationName:CPNotificationConnectionOnline object:nil];
                        _isOnline = YES;
                    }
                }
                break;
                
            default:{
                    if (_isOnline) {
                        [[NSNotificationCenter defaultCenter]postNotificationName:CPNotificationConnectionLost object:nil];
                        BFLog(@"connection lost");
                        _isOnline = NO;
                    }
                }
                break;
        }
    }
}

@end

//
//  NetworkManager.h
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApiProtocol.h"

@interface NetworkManager : NSObject



+ (instancetype)sharedManager;
+ (instancetype)sharedManagerWithSettings:(Class)settingsClass;

- (id<ApiProtocol>)getNetworkManager;
- (void)checkDomainVersionAndSSLConnection:(void(^)(NSString *domainVersion, NSString *correctHostURL))handler;
- (void)prepareForCheck;

#pragma mark - Debug Methods


@end

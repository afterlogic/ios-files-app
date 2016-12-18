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
- (id<ApiProtocol>)getNetworkManager;
- (void)checkDomainVersionAndSSLConnection:(void(^)(NSString *domainVersion, NSString *correctHostURL))handler;

@end

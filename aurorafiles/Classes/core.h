//
//  core.h
//  aurorafiles
//
//  Created by Cheshire on 18.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuroraModuleProtocol.h"
@interface core : NSObject <AuroraModuleProtocol>
+ (instancetype) sharedInstance;
- (NSString *)moduleName;
- (void)pingHostWithCompletion:(void (^)(BOOL isP8, NSError *error))handler;
- (void)logoutWithCompletion:(void (^)(BOOL succsess, NSError *error))handler;
- (void)signInWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(NSDictionary *data, NSError *error))handler;
- (void)getUserWithCompletion:(void(^)(NSString *publicID, NSError *error))handler;
@end

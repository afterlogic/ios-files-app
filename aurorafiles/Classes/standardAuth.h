//
//  standardAuth.h
//  aurorafiles
//
//  Created by Cheshire on 18.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuroraModuleProtocol.h"
@interface standardAuth : NSObject <AuroraModuleProtocol>

+ (instancetype) sharedInstance;
- (void)signInWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(NSDictionary *data, NSError *error))handler;
@end

//
//  AuroraModuleProtocol.h
//  aurorafiles
//
//  Created by Cheshire on 19.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol AuroraModuleProtocol <NSObject>
- (id)init;
+ (instancetype) sharedInstance;
- (NSString *)moduleName;

@end

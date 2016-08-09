//
//  ConnectionProvider.h
//  aurorafiles
//
//  Created by Cheshire on 05.08.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface ConnectionProvider : NSObject

+ (instancetype) sharedInstance;


- (void) startNotification;
- (void) stopNotification;

@end

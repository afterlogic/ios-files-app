//
//  ApiP8.h
//  
//
//  Created by Cheshire on 18.10.16.
//
//

#import <Foundation/Foundation.h>
#import "standardAuth.h"
#import "core.h"
#import "files.h"

@interface ApiP8 : NSObject
+ (core *)coreModule;
+ (standardAuth *)standardAuthModule;
+ (files *)filesModule;
@end

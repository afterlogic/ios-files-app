//
//  ApiP8.m
//  
//
//  Created by Cheshire on 18.10.16.
//
//

#import "ApiP8.h"
#import "standardAuth.h"
#import "core.h"
#import "files.h"

@implementation ApiP8

+(core *)coreModule{
    return [core sharedInstance];
}

+(standardAuth *)standardAuthModule{
    return [standardAuth sharedInstance];
}

+(files *)filesModule{
    return [files sharedInstance];
}

@end

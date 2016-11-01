//
//  standardAuth.m
//  aurorafiles
//
//  Created by Cheshire on 18.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "standardAuth.h"
#import "Folder.h"
#import "AFNetworking.h"
#import "Settings.h"
#import "NSURLRequest+requestGenerator.h"

@interface standardAuth(){
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation standardAuth 

static NSString *moduleName = @"Core";
static NSString *methodLogin = @"Login";

-(id)init{
    self = [super init ];
    if(self){
        manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
    }
    return self;
}

+ (instancetype) sharedInstance
{
    static standardAuth *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[standardAuth alloc] init];
    });
    return sharedInstance;
}

-(void)cancelOperations{
    [manager.operationQueue cancelAllOperations];
}

-(NSString *)moduleName{
    return moduleName;
}

@end

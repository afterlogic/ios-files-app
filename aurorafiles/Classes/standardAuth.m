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

#import <AFNetworking+AutoRetry/AFHTTPRequestOperationManager+AutoRetry.h>

static int retryCount = 0;
static const int retryInterval = 5;

@interface standardAuth(){
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation standardAuth 

static NSString *moduleName = @"StandardAuth";
static NSString *methodGetUsersAccount = @"GetUserAccounts";

-(id)init{
    self = [super init ];
    if(self){
        manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
        
//        retryCount = 3;
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

- (void)getUserAccountsWithCompletion:(void(^)(NSString *publicID, NSError *error))handler{
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetUsersAccount,
//                                                                    @"AuthToken":[Settings authToken]
                                                                           }].mutableCopy;
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSString *userInfoResult = @"";
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }else{
                if ([json count] < 2) {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                }
                if ([[json objectForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]) {
                    NSNumber *errorCode = [json objectForKey:@"ErrorCode"];
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                }else if ([[json objectForKey:@"Result"] isKindOfClass:[NSDictionary class]]){
                    NSDictionary *userData = [json objectForKey:@"Result"];
                    userInfoResult = [userData valueForKeyPath:@"login"];
                }

            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(nil,error);
                return ;
            }
            
            handler(userInfoResult,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            handler(nil,error);
        });
    } autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
    

}

-(void)cancelOperations{
    retryCount = 0;
    [manager.operationQueue cancelAllOperations];
}

-(NSString *)moduleName{
    return moduleName;
}

@end

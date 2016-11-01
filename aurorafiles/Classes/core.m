//
//  core.m
//  aurorafiles
//
//  Created by Cheshire on 18.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "core.h"
#import "Folder.h"
#import "AFNetworking.h"
#import "Settings.h"
#import "NSURLRequest+requestGenerator.h"

@interface core(){
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation core

static NSString *moduleName = @"Core";
static NSString *methodPing = @"Ping";
static NSString *methodLogout = @"Logout";
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
    static core *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[core alloc] init];
    });
    return sharedInstance;
}

- (NSString *)moduleName{
    return moduleName;
}

-(void)pingHostWithCompletion:(void (^)(BOOL isP8, NSError *error))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodPing}];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            BOOL isP8 = NO;
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    NSDictionary *resultDitc = [[json valueForKey:@"Result"]lastObject];
                    NSString *result = [resultDitc valueForKey:@"Result"];
                    if ([result isEqualToString:@"Pong"]) {
                        isP8 = YES;
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];
                }
            }else{
//                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];
            }
            handler(isP8,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            NSError *offlineError;
            if ([Settings domain] && [Settings login]) {
                 offlineError = [[NSError alloc]initWithDomain:@"NSURLDomain" code:666 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Something went wrong.Maybe you dont have internet connection =(", @"")}];
                handler(nil,offlineError);
                return ;
            }
            handler(nil,error);
        });
    }];
    
    [manager.operationQueue addOperation:operation];
}

-(void)logoutWithCompletion:(void (^)(BOOL succsess, NSError *error))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodPing,
                                                                    @"AuthToken":[Settings authToken]}];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            BOOL success = NO;
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    if ([[json valueForKey:@"Result"]count] >=2) {
                        NSDictionary *resultDitc = [[json valueForKey:@"Result"]lastObject];
                        NSString *result = [resultDitc valueForKey:@"Result"];
                        if ([result isEqualToString:@"Pong"]) {
                            success = YES;
                        }
                    }

                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];
            }
            handler(success,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            NSError *offlineError;
            if ([Settings domain] && [Settings login]) {
                offlineError = [[NSError alloc]initWithDomain:@"NSURLDomain" code:666 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Something went wrong.Maybe you dont have internet connection =(", @"")}];
                handler(nil,offlineError);
                return ;
            }
            handler(nil,error);
        });
    }];
    
    [manager.operationQueue addOperation:operation];
}

- (void)signInWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(NSDictionary *data, NSError *error))handler{
    
    //    NSURLRequest * request = [self requestWithDictionary:@{@"Action":signInAction,@"Email":email, @"IncPassword":password}];
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodLogin,
                                                                    @"Parameters":@{@"Login":email,
                                                                                    @"Password":password,
                                                                                    @"SignMe":@"true"}} login:YES];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    NSString *token = @"";
                    for (NSDictionary *dict in [json valueForKey:@"Result"]) {
                        if ([[dict valueForKey:@"Method"]isEqualToString:methodLogin] && [[dict valueForKey:@"Module"]isEqualToString:moduleName] ) {
                            if ([[dict valueForKey:@"Result"] isKindOfClass:[NSDictionary class]]) {
                                token = [dict valueForKeyPath:@"Result.AuthToken"];
                            }
                        }
                    }
                    NSNumber * accountID = [json objectForKey:@"AuthenticatedUserId"];
                    if (accountID)
                    {
                        [Settings setCurrentAccount:accountID];
                    }
                    if (token.length)
                    {
                        [Settings setAuthToken:token];
                        error = nil;
                    }
                    else
                    {
                        error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The username or password you entered is incorrect", @"")}];
                }
            }
            handler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(nil,error);
        });
    }];
    
    [manager.operationQueue addOperation:operation];
    
}

-(void)cancelOperations{
    [manager.operationQueue cancelAllOperations];
}


@end

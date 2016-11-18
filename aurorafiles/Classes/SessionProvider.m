//
//  SessionProvider.m
//  p7mobile
//
//  Created by Akopyants Michael on 25/03/15.
//  Copyright (c) 2015 Afterlogic Rus. All rights reserved.
//

#import "SessionProvider.h"
#import "API.h"
#import "Settings.h"
#import "KeychainWrapper.h"
#import "ApiP8.h"
#import "StorageManager.h"

static int const kNUMBER_OF_RETRIES = 6;

@interface SessionProvider(){
    int operationCounter;
}
@end
@implementation SessionProvider

+ (instancetype)sharedManager
{
    static SessionProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SessionProvider alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        operationCounter = 0;
    }
    
    return self;
}

- (void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline, BOOL isP8 ))handler
{
            if ([[Settings version] isEqualToString:@"P8"]) {
                [Settings setLastLoginServerVersion:@"P8"];
                NSLog(@"host version is 8 or above");
                [[ApiP8 coreModule] getUserWithCompletion:^(NSString *publicID, NSError *error) {
                    if ([publicID isEqualToString:[Settings login]]) {
                        handler(YES,NO,YES);
                    }else{
                        NSString * email = [Settings login];
                        NSString * password = [Settings password];
                        if (email.length && password.length)
                        {
                            [[ApiP8 coreModule] signInWithEmail:email andPassword:password completion:^(NSDictionary *data, NSError *error) {
                                if (error)
                                {
                                    handler(NO,error,YES);
                                    return;
                                }
                                handler(YES,NO,YES);
                            }];
                        }else{
                            handler(NO,NO,YES);
                        }
                    }
                }];
            }else{
                NSLog(@"host version smaller than 8");
                [Settings setLastLoginServerVersion:@"P7"];
                [[API sharedInstance] checkIsAccountAuthorisedWithCompletion:^(NSDictionary *data, NSError *error) {
                    if (!error)
                    {
                        if ([[data valueForKey:@"Result"] isKindOfClass:[NSDictionary class]])
                        {
                            if (data[@"Result"][@"offlineMod"]) {
                                handler (YES,YES, NO);
                            }
                            handler (YES,NO,NO);
                        }
                        else
                        {
                            if([[data valueForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]){
                                NSNumber *errorCode = data[@"ErrorCode"];
                                if (errorCode.intValue == 101 || errorCode.intValue == 103 || errorCode.integerValue == 102) {
                                    NSString * email = [Settings login];
                                    NSString * password = [Settings password];
                                    if (email.length && password.length)
                                    {
                                        [self authroizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error){
                                            handler(isAuthorised,NO, NO);
                                        }];
                                        return;
                                    }else{
                                        handler(NO,NO, NO);
                                        return;
                                    }
                                }
                                
                            }
                            else
                            {
                                handler(NO,NO, NO);
                            }
                        }
                        return ;
                    }
                    else
                    {
                        NSString * email = [Settings login];
                        NSString * password = [Settings password];
                        if (email.length && password.length)
                        {
                            [self authroizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error){
                                handler(isAuthorised,NO, NO);
                            }];
                            return;
                        }
                        else
                        {
                            handler (NO,NO, NO);
                            return;
                        }
                    }
                }];
            }

}


- (void) authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL,NSError*))handler
{
    [[ApiP8 coreModule] pingHostWithCompletion:^(BOOL isP8, NSError *error) {
        if (isP8) {
            if (![[Settings version] isEqualToString:@"P8"]) {
                [[StorageManager sharedManager]deleteAllObjects:@"Folder"];
            }
            [Settings setLastLoginServerVersion:@"P8"];
            NSLog(@"host version is 8 or above");
            [[ApiP8 coreModule] signInWithEmail:email andPassword:password completion:^(NSDictionary *data, NSError *error) {
                if (error)
                {
                    handler(NO,error);
                    return;
                }
                handler(YES,error);

            }];
        }else{
            NSLog(@"host version smaller than 8");
            if (![[Settings version] isEqualToString:@"P7"]) {
                [[StorageManager sharedManager]deleteAllObjects:@"Folder"];
            }
            [Settings setLastLoginServerVersion:@"P7"];
            [[API sharedInstance] getAppDataCompletionHandler:^(NSDictionary *result, NSError *error) {
                if (error)
                {
                    handler (NO,error);
                    return ;
                }
                NSNumber *loginFormType = [NSNumber new];
                if ([[result valueForKeyPath:@"Result.Token"] isKindOfClass:[NSString class]]) {
                    [Settings setToken:[result valueForKeyPath:@"Result.Token"]];
                }
                if ([[result valueForKeyPath:@"Result.App.LoginFormType"] isKindOfClass:[NSNumber class]]) {
                    loginFormType = [result valueForKeyPath:@"Result.App.LoginFormType"];
                }
                [[API sharedInstance] signInWithEmail:email andPassword:password loginType:[loginFormType stringValue] completion:^(NSDictionary *result, NSError *error) {
                    if([[result valueForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]){
                        NSNumber *errorCode = result[@"ErrorCode"];
                        if (errorCode.intValue == 101 || errorCode.intValue == 103 || errorCode.intValue == 102 ) {
                            NSString * email = [Settings login];
                            NSString * password = [Settings password];
                            if (email.length && password.length)
                            {
                                [self authroizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error){
                                    handler(isAuthorised,error);
                                }];
                                return;
                            }else{
                                handler(NO,error);
                                return;
                            }
                        }
                        
                    }else{
                        
                    }
                    if (error)
                    {
                        handler(NO,error);
                        return;
                    }
                    handler(YES,error);
                }];
            }];

        }
    }];
}

- (void)deathorizeWithCompletion:(void (^)(BOOL))handler
{

}

- (void)checkSSLConnection:(void (^)(NSString *))handler{
    __block NSError *p8Error = [NSError new];
    operationCounter += 1;
    if (operationCounter >= kNUMBER_OF_RETRIES) {
        operationCounter = 0;
        handler(nil);
    }else{
        [[ApiP8 coreModule] pingHostWithCompletion:^(BOOL isP8, NSError *error){
            p8Error = error;
            if (isP8 && !error){
                NSString * scheme = [[NSURL URLWithString:[Settings domain]] scheme];
                NSString * urlString = [NSString stringWithFormat:@"%@%@",scheme ? @"" : @"https://",[Settings domain]];
                [Settings setDomain:urlString];
                handler([Settings domain]);
                operationCounter = 0;
                return;
            }else if(!isP8 && error){
                [[API sharedInstance]getAppDataCompletionHandler:^(NSDictionary *data, NSError *error) {
                    if (error && p8Error) {
                        NSURL * url = [NSURL URLWithString:[Settings domain]];
                        NSString *resourceSpec = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
                        NSString *scheme = @"";
                        if ([[url scheme] isEqualToString:@"http://"] || ![url scheme]) {
                            scheme = @"https://";
                        }else{
                            scheme = @"http://";
                        }
                        NSString *domain = [NSString stringWithFormat:@"%@%@",scheme,resourceSpec];
                        [Settings setDomain: domain];
                        [self checkSSLConnection:^(NSString *domain) {
                            handler(domain);
                        }];
                    }else{
                        NSString * scheme = [[NSURL URLWithString:[Settings domain]] scheme];
                        NSString * urlString = [NSString stringWithFormat:@"%@%@",scheme ? @"" : @"https://",[Settings domain]];
                        [Settings setDomain:urlString];
                        handler([Settings domain]);
                        operationCounter = 0;
                        return;
                    }
                }];
            }else{
                NSString * scheme = [[NSURL URLWithString:[Settings domain]] scheme];
                NSString * urlString = [NSString stringWithFormat:@"%@%@",scheme ? @"" : @"https://",[Settings domain]];
                [Settings setDomain:urlString];
                handler([Settings domain]);
                operationCounter = 0;
                return;
            }
        }];
    }
}

@end

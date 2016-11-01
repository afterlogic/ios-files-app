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
@implementation SessionProvider

+ (void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline, BOOL isP8 ))handler
{

    if ([[Settings version] isEqualToString:@"P8"]) {
        [Settings setLastLoginServerVersion:@"P8"];
        NSLog(@"host version is 8 or above");
        [[ApiP8 filesModule] getUserFilestorageQoutaWithCompletion:^(NSString *publicID, NSError *error) {
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
                        if (errorCode.longValue == 101) {
                            NSString * email = [Settings login];
                            NSString * password = [Settings password];
                            if (email.length && password.length)
                            {
                                [SessionProvider authroizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error){
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
                    [SessionProvider authroizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error){
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


+ (void) authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL,NSError*))handler
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
                if ([[result valueForKeyPath:@"Result.App.LoginFormType"] isKindOfClass:[NSNumber class]]) {
                    loginFormType = [result valueForKeyPath:@"Result.App.LoginFormType"];
                }
                
                [[API sharedInstance] signInWithEmail:email andPassword:password loginType:[loginFormType stringValue] completion:^(NSDictionary *result, NSError *error) {
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

+ (void)deathorizeWithCompletion:(void (^)(BOOL))handler
{
	
}

@end

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

@implementation SessionProvider

+ (void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline ))handler
{
    [[API sharedInstance] checkIsAccountAuthorisedWithCompletion:^(NSDictionary *data, NSError *error) {
        if (!error)
        {
            if ([[data valueForKey:@"Result"] isKindOfClass:[NSDictionary class]])
            {
                if (data[@"Result"][@"offlineMod"]) {
                    handler (YES,YES);
                }
                handler (YES,NO);
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
                                handler(isAuthorised,NO);
                            }];
                            return;
                        }else{
                            handler(NO,NO);
                            return;
                        }
                    }
                    
                }
                else
                {
                    handler(NO,NO);
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
                    handler(isAuthorised,NO);
                }];
                return;
            }
            else
            {
                handler (NO,NO);
                return;
            }
        }
    }];
    


	
	
}


+ (void) authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL,NSError*))handler
{
	[[API sharedInstance] getAppDataCompletionHandler:^(NSDictionary *result, NSError *error) {
		if (error)
		{
			handler (NO,error);
			return ;
		}
		
		[[API sharedInstance] signInWithEmail:email andPassword:password completion:^(NSDictionary *result, NSError *error) {
            if (error)
			{
				handler(NO,error);
				return;
			}
			handler(YES,error);
			}];
	}];

}

+ (void)deathorizeWithCompletion:(void (^)(BOOL))handler
{
	
}

@end

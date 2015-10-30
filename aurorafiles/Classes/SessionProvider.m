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
@implementation SessionProvider

+ (void)checkAuthorizeWithCompletion:(void (^)(BOOL))handler
{
	if (![Settings authToken].length || ![Settings token].length)
	{
		handler (NO);
		return;
	}
	
	[[API sharedInstance] checkIsAccountAuthorisedWithCompletion:^(NSDictionary *data, NSError *error) {

		if ([[data valueForKey:@"Result"] isKindOfClass:[NSDictionary class]])
		{
			handler (YES);
		}
		else
		{
			handler(NO);
		}
	}];
}


+ (void) authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL))handler
{
	[[API sharedInstance] getAppDataCompletionHandler:^(NSDictionary *result, NSError *error) {
		if (error)
		{
			handler (NO);
			return ;
		}
		
		[[API sharedInstance] signInWithEmail:email andPassword:password completion:^(NSDictionary *result, NSError *error) {
            if (error)
			{
				handler(NO);
				return;
			}
			handler(YES);
			}];
	}];

}

+ (void)deathorizeWithCompletion:(void (^)(BOOL))handler
{
	
}

@end

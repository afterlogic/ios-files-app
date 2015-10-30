//
//  Settings.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "Settings.h"

@implementation Settings

+ (NSString*)domain
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"mail_domain"];
}

+ (void)setDomain:(NSString *)domain
{
    [[NSUserDefaults standardUserDefaults] setValue:domain forKey:@"mail_domain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setAuthToken:(NSString *)authToken
{
    [[NSUserDefaults standardUserDefaults] setValue:authToken forKey:@"auth_token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)authToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"auth_token"];
}

+ (void)setToken:(NSString *)token
{
    [[NSUserDefaults standardUserDefaults] setValue:token forKey:@"token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)token
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
}

+ (void)setCurrentAccount:(NSNumber *)currentAccount
{
    [[NSUserDefaults standardUserDefaults] setValue:currentAccount forKey:@"current_account"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSNumber*)currentAccount
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"current_account"];
}


@end

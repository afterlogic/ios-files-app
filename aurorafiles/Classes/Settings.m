//
//  Settings.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "Settings.h"

@implementation Settings

+ (NSUserDefaults*)sharedDefaults
{
    return [[NSUserDefaults alloc] initWithSuiteName:@"group.afterlogic.aurorafiles"];
}

+ (NSString*)domain
{
    return [[Settings sharedDefaults] valueForKey:@"mail_domain"];
}

+ (void)setDomain:(NSString *)domain
{
    [[Settings sharedDefaults] setValue:domain forKey:@"mail_domain"];
    [[Settings sharedDefaults] synchronize];
}

+ (void)setAuthToken:(NSString *)authToken
{
    [[Settings sharedDefaults] setValue:authToken forKey:@"auth_token"];
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)authToken
{
    return [[Settings sharedDefaults] valueForKey:@"auth_token"];
}

+ (void)setLogin:(NSString*)login
{
    [[Settings sharedDefaults] setValue:login forKey:@"auth_login"];
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)login
{
    return [[Settings sharedDefaults] valueForKey:@"auth_login"];
}

+ (void)setPassword:(NSString*)password
{
    [[Settings sharedDefaults] setValue:password forKey:@"auth_password"];
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)password
{
    return [[Settings sharedDefaults] valueForKey:@"auth_password"];
}

+ (void)setToken:(NSString *)token
{
    [[Settings sharedDefaults] setValue:token forKey:@"token"];
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)token
{
    return [[Settings sharedDefaults] valueForKey:@"token"];
}

+ (void)setCurrentAccount:(NSNumber *)currentAccount
{
    [[Settings sharedDefaults] setValue:currentAccount forKey:@"current_account"];
    [[Settings sharedDefaults] synchronize];
}

+ (NSNumber*)currentAccount
{
    return [[Settings sharedDefaults] valueForKey:@"current_account"];
}


@end

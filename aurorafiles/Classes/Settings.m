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

+ (NSString *)domainScheme{
    NSString *sch = [[Settings sharedDefaults] valueForKey:@"domain_sсheme"];
    DDLogInfo(@"⚠️ current domain Scheme is -> %@", sch);
    return sch;
}

+ (void)setDomainScheme:(NSString *)scheme{
    [[Settings sharedDefaults] setValue:scheme forKey:@"domain_sсheme"];
    [[Settings sharedDefaults] synchronize];
}

+ (void)setAuthToken:(NSString *)authToken
{
    [[Settings sharedDefaults] setValue:authToken forKey:@"auth_token"];
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)authToken
{
    NSString *token = [[Settings sharedDefaults] valueForKey:@"auth_token"];
    
    return token ? token :@"";
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

+ (void)setFirstRun:(NSString *)isFirstRun{
    [[Settings sharedDefaults] setValue:isFirstRun forKey:@"first_run"];
    [[Settings sharedDefaults] synchronize];
}

+ (NSString *)isFirstRun{
    return [[Settings sharedDefaults] valueForKey:@"first_run"];
}

+ (void)setLastLoginServerVersion:(NSString *)version{
    [[Settings sharedDefaults] setValue:version forKey:@"hostVersion"];
    [[Settings sharedDefaults] synchronize];
}
+ (NSString *)version{
    DDLogInfo(@"⚠️ current host Version is -> %@", [[Settings sharedDefaults] valueForKey:@"hostVersion"]);
    return [[Settings sharedDefaults] valueForKey:@"hostVersion"];
}

+ (void)saveLastUsedFolder:(NSDictionary *)folder{
    [[Settings sharedDefaults]setValue:folder forKey:@"lastUsedFolder"];
    [[Settings sharedDefaults]synchronize];
}

+(NSDictionary *)getLastUsedFolder{
    return [[Settings sharedDefaults] valueForKey:@"lastUsedFolder"];
}

+(void)clearSettings{
    [Settings setLastLoginServerVersion:nil];
    [Settings setCurrentAccount:nil];
    [Settings setToken:nil];
    [Settings setPassword:nil];
    [Settings setAuthToken:nil];
    [Settings setDomainScheme:nil];

    NSString * lastLoginServerVersion = [Settings version];
    NSString * currentAccount = [Settings currentAccount];
    NSString * token = [Settings token];
    NSString * password = [Settings password];
    NSString * authToken = [Settings authToken];
    NSString * domainScheme = [Settings domainScheme];

    DDLogInfo(@"Settings after clear ->  %@ %@ %@ %@ %@ %@",lastLoginServerVersion,currentAccount,token,password,authToken,domainScheme);
}

@end

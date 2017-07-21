//
//  Settings.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "Settings.h"

@implementation Settings

+ (NSUserDefaults*)sharedDefaults{
    return [[NSUserDefaults alloc] initWithSuiteName:@"group.afterlogic.aurorafiles"];
}

+ (NSString*)domain{
    return [[Settings sharedDefaults] valueForKey:@"mail_domain"];
}

+ (void)setDomain:(NSString *)domain{
    [[Settings sharedDefaults] setValue:domain forKey:@"mail_domain"];
    DDLogInfo(@"⚠️ current domain setted to -> %@", domain);
    [[Settings sharedDefaults] synchronize];
}

+ (NSString *)domainScheme{
    NSString *sch = [[Settings sharedDefaults] valueForKey:@"domain_sсheme"];
//    DDLogInfo(@"⚠️ current domain Scheme is -> %@", sch);
    return sch;
}

+ (void)setDomainScheme:(NSString *)scheme{
    [[Settings sharedDefaults] setValue:scheme forKey:@"domain_sсheme"];
    DDLogInfo(@"⚠️ current domain Scheme setted to -> %@", scheme);
    [[Settings sharedDefaults] synchronize];
}

+ (void)setAuthToken:(NSString *)authToken{
    [[Settings sharedDefaults] setValue:authToken forKey:@"auth_token"];
    DDLogInfo(@"⚠️ current authToken setted to -> %@", authToken);
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)authToken{
    NSString *token = [[Settings sharedDefaults] valueForKey:@"auth_token"];
    
    return token ? token :@"";
}

+ (void)setLogin:(NSString*)login{
    [[Settings sharedDefaults] setValue:login forKey:@"auth_login"];
    DDLogInfo(@"⚠️ current login setted to -> %@", login);
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)login{
    return [[Settings sharedDefaults] valueForKey:@"auth_login"];
}

+ (void)setPassword:(NSString*)password{
    [[Settings sharedDefaults] setValue:password forKey:@"auth_password"];
    DDLogInfo(@"⚠️ current password setted to -> %@", password);
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)password{
    return [[Settings sharedDefaults] valueForKey:@"auth_password"];
}

+ (void)setToken:(NSString *)token{
    [[Settings sharedDefaults] setValue:token forKey:@"token"];
    DDLogInfo(@"⚠️ current token setted to -> %@", token);
    [[Settings sharedDefaults] synchronize];
}

+ (NSString*)token{
    return [[Settings sharedDefaults] valueForKey:@"token"];
}

+ (void)setCurrentAccount:(NSNumber *)currentAccount{
    [[Settings sharedDefaults] setValue:currentAccount forKey:@"current_account"];
    DDLogInfo(@"⚠️ current account setted to -> %@", currentAccount);
    [[Settings sharedDefaults] synchronize];
}

+ (NSNumber*)currentAccount{
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
    DDLogInfo(@"⚠️ current host Version setted to -> %@", version);
    [[Settings sharedDefaults] synchronize];
}
+ (NSString *)lastLoginServerVersion{
//    DDLogInfo(@"⚠️ current host Version is -> %@", [[Settings sharedDefaults] valueForKey:@"hostVersion"]);
    return [[Settings sharedDefaults] valueForKey:@"hostVersion"];
}

+ (void)saveLastUsedFolder:(NSDictionary *)folder{
    [[Settings sharedDefaults]setValue:folder forKey:@"lastUsedFolder"];
    DDLogInfo(@"⚠️ current lastUsedFolder setted to -> %@", folder);
    [[Settings sharedDefaults]synchronize];
}

+(NSDictionary *)getLastUsedFolder{
    return [[Settings sharedDefaults] valueForKey:@"lastUsedFolder"];
}

+(void)setIsLogedIn:(BOOL)isLogedIn{
    NSNumber* numberWithBool = [NSNumber numberWithBool:isLogedIn];
    [[Settings sharedDefaults]setValue:numberWithBool forKey:@"isLogedIn"];
    [[Settings sharedDefaults]synchronize];
}

+(BOOL)getIsLogedIn{
    NSNumber* numberWithBool = [[Settings sharedDefaults] valueForKey:@"isLogedIn"];
    return numberWithBool.boolValue;
}

+(void)clearSettings{
    NSArray *filedsForRemove = @[@"hostVersion",@"current_account",@"token",@"auth_password",@"auth_token",@"domain_sсheme",@"lastUsedFolder",@"isLogedIn"];
    NSDictionary * dict = [[Settings sharedDefaults] dictionaryRepresentation];
    for (NSString* key in dict) {
        if ([filedsForRemove containsObject:key]) {
            [[Settings sharedDefaults]removeObjectForKey:key];
        }
    }
//    [Settings setLastLoginServerVersion:nil];
//    [Settings setCurrentAccount:nil];
//    [Settings setToken:nil];
//    [Settings setPassword:nil];
//    [Settings setAuthToken:nil];
//    [Settings setDomainScheme:nil];
//    [Settings saveLastUsedFolder:nil];
//    [Settings setIsLogedIn:NO];

    NSString * lastLoginServerVersion = [Settings lastLoginServerVersion];
    NSString * currentAccount = [Settings currentAccount].stringValue;
    NSString * token = [Settings token];
    NSString * password = [Settings password];
    NSString * authToken = [Settings authToken];
    NSString * domainScheme = [Settings domainScheme];

    DDLogInfo(@"Settings after clear ->  %@ %@ %@ %@ %@ %@",lastLoginServerVersion,currentAccount,token,password,authToken,domainScheme);
}

@end

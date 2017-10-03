//
//  Settings.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "Settings.h"
#import "FXKeychain.h"
#import "AuroraSettings.h"

static NSString  *serviceName = @"auroraFiles";
static NSString  *accessGroupName = @"com.afterlogic.aurorafiles";


static NSString  *kc_login = @"login";
static NSString  *kc_password = @"password";
static NSString  *kc_authToken = @"authToken";
static NSString  *kc_p7token = @"p7Token";

@interface Settings (){
    
}

@end

@implementation Settings


#pragma mark - Keychain settings

+(FXKeychain *)keychainWrapper{
    static FXKeychain *keychainItem = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keychainItem = [FXKeychain defaultKeychain];
    });
    return keychainItem;
}

+(void)saveItem:(id<NSCoding>)item forKey: (NSString *)key{
    [[Settings keychainWrapper]setObject:item forKey:key];
}

+(id)itemforKey: (NSString *)key{
    return [[Settings keychainWrapper]objectForKey:key];
}

+(void)deleteItemForKey: (NSString *)key{
    [[Settings keychainWrapper]removeObjectForKey:key];
}

+ (void)setLogin:(NSString*)login{
    [Settings saveItem:login forKey:kc_login];
}

+ (NSString*)login{
    return [Settings itemforKey:kc_login];
}

+ (void)setPassword:(NSString*)password{
    [Settings saveItem:password forKey:kc_password];
}

+ (NSString*)password{
    return [Settings itemforKey:kc_password];
}

+ (void)setAuthToken:(NSString *)authToken{
    [Settings saveItem:authToken forKey:kc_authToken];
}

+ (NSString*)authToken{
    NSString *token = [Settings itemforKey:kc_authToken];
    return token ? token :@"";
}

+ (void)setToken:(NSString *)token{
    [Settings saveItem:token forKey:kc_p7token];
}

+ (NSString*)token{
    NSString *token = [Settings itemforKey:kc_p7token];
    return token ? token :@"";
}

+(void)clearKeychainSettings{
    [Settings deleteItemForKey:kc_login];
    [Settings deleteItemForKey:kc_password];
    [Settings deleteItemForKey:kc_authToken];
    [Settings deleteItemForKey:kc_p7token];
}

#pragma mark - UserDefault settings

+ (NSUserDefaults*)sharedDefaults{
    return [[NSUserDefaults alloc] initWithSuiteName:@"group.afterlogic.aurorafiles"];
}

+ (void)setDomain:(NSString *)domain{
//    [[Settings sharedDefaults] setValue:domain forKey:@"mail_domain"];
//    DDLogInfo(@"⚠️ current domain setted to -> %@", domain);
    //    [[Settings sharedDefaults] synchronize];
    
    [[AuroraSettings sharedSettings]setDomain:domain];
}

+ (NSString*)domain{
//    return [[Settings sharedDefaults] valueForKey:@"mail_domain"];
    return [[AuroraSettings sharedSettings]domain];
}



+ (NSString *)domainScheme{
//    NSString *sch = [[Settings sharedDefaults] valueForKey:@"domain_sсheme"];
    NSString *sch = [[AuroraSettings sharedSettings]domainScheme];
    return sch;
}

+ (void)setDomainScheme:(NSString *)scheme{
//    [[Settings sharedDefaults] setValue:scheme forKey:@"domain_sсheme"];
    [[AuroraSettings sharedSettings]setDomainScheme:scheme];
    DDLogInfo(@"⚠️ current domain Scheme setted to -> %@", scheme);
//    [[Settings sharedDefaults] synchronize];
}


+ (void)setCurrentAccount:(NSString *)currentAccount{
    NSString *currentAccID = [NSString stringWithString:currentAccount];
    [[AuroraSettings sharedSettings] setCurrentAccaunt:currentAccID];
    DDLogInfo(@"⚠️ current account setted to -> %@", currentAccount);
}

+ (NSString*)currentAccount{
    return [[AuroraSettings sharedSettings] currentAccaunt];
}

+ (void)setFirstRun:(NSString *)isFirstRun{
    [[AuroraSettings sharedSettings]setFirstRun:isFirstRun];
}

+ (NSString *)isFirstRun{
    return [[AuroraSettings sharedSettings] firstRun];
}

+ (void)setLastLoginServerVersion:(NSString *)version{
    NSString *hostVersion = [NSString stringWithFormat:@"%@",version];
    [[AuroraSettings sharedSettings] setLastLoginServerVersion:hostVersion];
}

+ (NSString *)lastLoginServerVersion{
    NSString *version = [[AuroraSettings sharedSettings] lastLoginServerVersion];
    return version;
}

+ (void)saveLastUsedFolder:(NSDictionary *)folder{
//    [[Settings sharedDefaults]setValue:folder forKey:@"lastUsedFolder"];
    
//    [[Settings sharedDefaults]synchronize];
    [[AuroraSettings sharedSettings] setLastUsedFolder:folder];
    DDLogInfo(@"⚠️ current lastUsedFolder setted to -> %@", folder);
}

+(NSDictionary *)getLastUsedFolder{
//    return [[Settings sharedDefaults] valueForKey:@"lastUsedFolder"];
    return [[AuroraSettings sharedSettings]lastUsedFolder];
}

+(void)setIsLogedIn:(BOOL)isLogedIn{
    NSNumber* numberWithBool = [NSNumber numberWithBool:isLogedIn];
//    [[Settings sharedDefaults]setValue:numberWithBool forKey:@"isLogedIn"];
    
    [[AuroraSettings sharedSettings]setIsLogedIn:numberWithBool];
//    [[Settings sharedDefaults]synchronize];
}

+(BOOL)getIsLogedIn{
//    NSNumber* numberWithBool = [[Settings sharedDefaults] valueForKey:@"isLogedIn"];
//    return numberWithBool.boolValue;
    return [[AuroraSettings sharedSettings]isLogedIn].boolValue;
}

+ (void)saveAuroraSettingsToUserDefaults{
    NSMutableArray *settings = [NSMutableArray new];
    [settings addObject:[AuroraSettings sharedSettings]];
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:settings];
    [[Settings sharedDefaults]setObject:encodedObject  forKey:auroraSettingsKey];
    [[Settings sharedDefaults]synchronize];
}

+(void)saveSettings{
    [Settings saveAuroraSettingsToUserDefaults];
}

+(void)clearSettings{
    [Settings clearKeychainSettings];
    [[AuroraSettings sharedSettings]clearAuroraSettings];
//    [[Settings sharedDefaults]removeObjectForKey:auroraSettingsKey];

    NSString * lastLoginServerVersion = [Settings lastLoginServerVersion];
    NSString * currentAccount = [Settings currentAccount];
    NSString * domainScheme = [Settings domainScheme];

    DDLogInfo(@"Settings after clear ->  1%@ 2%@ 3%@",lastLoginServerVersion,currentAccount,domainScheme);
}



@end

//
//  Settings.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "Settings.h"
#import "FXKeychain.h"

static NSString  *serviceName = @"auroraFiles";
static NSString  *accessGroupName = @"com.afterlogic.aurorafiles";


static NSString  *lk_login = @"login";
static NSString  *lk_password = @"password";
static NSString  *lk_authToken = @"authToken";
static NSString  *lk_p7token = @"p7Token";

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
//        NSError *error = nil;
//        [[Settings keychainWrapper]saveItem:item
//                      forKey:key
//                  forService:serviceName
//               inAccessGroup:accessGroupName
//           withAccessibility:FDKeychainAccessibleWhenUnlocked
//                       error:&error];
    [[Settings keychainWrapper]setObject:item forKey:key];
}

+(id)itemforKey: (NSString *)key{
//    dispatch_async(dispatch_get_main_queue(), ^id(){
//        NSError *error = nil;
//        return  [FDKeychain itemForKey:key
//                            forService:serviceName
//                         inAccessGroup:accessGroupName
//                                 error:&error];
//    });
    return [[Settings keychainWrapper]objectForKey:key];
}

+(void)deleteItemForKey: (NSString *)key{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSError *error = nil;
//        [FDKeychain deleteItemForKey:key
//                          forService:serviceName
//                       inAccessGroup:accessGroupName
//                               error:&error];
//    });
    [[Settings keychainWrapper]removeObjectForKey:key];
}

+ (void)setLogin:(NSString*)login{
    [Settings saveItem:login forKey:lk_login];
}

+ (NSString*)login{
    return [Settings itemforKey:lk_login];
}

+ (void)setPassword:(NSString*)password{
    [Settings saveItem:password forKey:lk_password];
}

+ (NSString*)password{
    return [Settings itemforKey:lk_password];
}

+ (void)setAuthToken:(NSString *)authToken{
    [Settings saveItem:authToken forKey:lk_authToken];
}

+ (NSString*)authToken{
    NSString *token = [Settings itemforKey:lk_authToken];
    return token ? token :@"";
}

+ (void)setToken:(NSString *)token{
    [Settings saveItem:token forKey:lk_p7token];
}

+ (NSString*)token{
    NSString *token = [Settings itemforKey:lk_p7token];
    return token ? token :@"";
}

#pragma mark - info.Plist settings



#pragma mark - UserDefault settings

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
    NSString *hostVersion = [NSString stringWithFormat:@"%@",version];
    [[Settings sharedDefaults] setValue:hostVersion forKey:@"hostVersion"];
    
    if ([[Settings sharedDefaults] synchronize]){
        DDLogInfo(@"⚠️ current host Version setted to -> %@", hostVersion);
    }else{
        DDLogInfo(@"⚠️ something goes wrong with host -> %@", hostVersion);
    }
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
    [Settings clearKeychainSettings];
    NSArray *fieldsForRemove = @[@"hostVersion",@"current_account",@"domain_sсheme",@"lastUsedFolder",@"isLogedIn"];
    NSDictionary * dict = [[Settings sharedDefaults] dictionaryRepresentation];
    for (NSString* key in dict) {
        if ([fieldsForRemove containsObject:key]) {
            [[Settings sharedDefaults]removeObjectForKey:key];
        }
    }

    NSString * lastLoginServerVersion = [Settings lastLoginServerVersion];
    NSString * currentAccount = [Settings currentAccount].stringValue;
    NSString * domainScheme = [Settings domainScheme];

    DDLogInfo(@"Settings after clear ->  1%@ 2%@ 3%@",lastLoginServerVersion,currentAccount,domainScheme);
}

+(void)clearKeychainSettings{
    [Settings deleteItemForKey:lk_login];
    [Settings deleteItemForKey:lk_password];
    [Settings deleteItemForKey:lk_authToken];
    [Settings deleteItemForKey:lk_p7token];
}

@end

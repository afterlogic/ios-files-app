//
//  Settings.h
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeychainWrapper.h"

static NSString * const auroraSettingsKey = @"auroraSettings";

@interface Settings : NSObject

+ (NSUserDefaults*)sharedDefaults;

+ (NSString*)domain;
+ (void)setDomain:(NSString *)domain;

+ (NSString *)domainScheme;
+ (void)setDomainScheme:(NSString *)scheme;

+ (void)setToken:(NSString*)token;
+ (NSString*)token;

+ (void)setAuthToken:(NSString*)authToken;
+ (NSString*)authToken;

+ (NSString*)currentAccount;
+ (void)setCurrentAccount:(NSString*)currentAccount;

+ (void)setLogin:(NSString*)login;
+ (NSString*)login;

+ (void)setPassword:(NSString*)password;
+ (NSString*)password;

+ (void)setFirstRun:(NSString *)isFirstRun;
+ (NSString *)isFirstRun;

+ (void)setLastLoginServerVersion:(NSString *)version;
+ (NSString *)lastLoginServerVersion;

+ (void)saveLastUsedFolder:(NSDictionary *)folder;
+ (NSDictionary *)getLastUsedFolder;

+ (void)setIsLogedIn:(BOOL)isLogedIn;
+ (BOOL)getIsLogedIn;

+ (void)saveSettings;

+ (void)clearSettings;

@end

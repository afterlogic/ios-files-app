//
//  Settings.h
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

+ (NSString*)domain;

+ (void)setDomain:(NSString *)domain;

+ (void)setToken:(NSString*)token;
+ (NSString*)token;

+ (void)setAuthToken:(NSString*)authToken;
+ (NSString*)authToken;

+ (NSNumber*)currentAccount;
+ (void)setCurrentAccount:(NSNumber*)currentAccount;

+ (void)setLogin:(NSString*)login;
+ (NSString*)login;

+ (void)setPassword:(NSString*)password;
+ (NSString*)password;

+ (void)setFirstRun:(NSString *)isFirstRun;
+ (NSString *)isFirstRun;

@end

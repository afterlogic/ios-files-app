//
//  SessionProvider.h
//  p7mobile
//
//  Created by Akopyants Michael on 25/03/15.
//  Copyright (c) 2015 Afterlogic Rus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApiProtocol.h"
#import "NetworkManager.h"

@interface SessionProvider : NSObject

//- (void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline, BOOL isP8 ))handler;
//
//- (void)authroizeEmail:(NSString*)email withPassword:(NSString*)password completion:(void (^)(BOOL authorized, NSError* error)) handler;
//
- (void)checkSSLConnection:(void (^)(NSString *domain)) handler;

- (void)checkDomainVersion:(void(^)(NSString *domainVersion, NSString *correctHostURL))handler;

- (void)updateDomainVersion:(void(^)())completionHandler;

- (void)checkWebAuthExistance:(void (^)(BOOL haveWebAuth, NSError *error))handler;

- (void)loginEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL success,NSError* error))handler;

- (void)logout:(void (^)(BOOL succsess, NSError *error))handler;

- (void)checkUserAuthorization:(void (^)(BOOL authorised, BOOL offline, BOOL isP8, NSError *error))handler;

- (void)userData:(void(^)(BOOL authorised, NSError *error))handler;

- (void)cancelAllOperations;

- (void)clear;

+ (instancetype)sharedManager;
+ (instancetype)sharedManagerWithSettings:(Class)settingsClass;
+ (instancetype)initWithApiManager:(id<ApiProtocol>)manager networkManager:(NetworkManager *)networkManager;
- (instancetype)initWithApiManager:(id<ApiProtocol>)manager networkManager:(NetworkManager *)networkManager;

@end

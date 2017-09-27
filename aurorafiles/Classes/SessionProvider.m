//
//  SessionProvider.m
//  p7mobile
//
//  Created by Akopyants Michael on 25/03/15.
//  Copyright (c) 2015 Afterlogic Rus. All rights reserved.
//

#import "SessionProvider.h"
#import "ApiP7.h"
#import "Settings.h"
#import "KeychainWrapper.h"
#import "ApiP8.h"
#import "StorageManager.h"


@interface SessionProvider(){
    int operationCounter;
    NetworkManager *networkManager;
}

@property (nonatomic, strong) id<ApiProtocol> actualApiManager; //
@property (nonatomic, strong) Class settings;
@end
@implementation SessionProvider

+ (instancetype)sharedManagerWithSettings:(Class)settingsClass{
    static SessionProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SessionProvider alloc] initWithSettings:settingsClass];
    });
    return sharedInstance;
}

+ (instancetype)sharedManager
{
    static SessionProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SessionProvider alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)initWithApiManager:(id<ApiProtocol>)manager networkManager:(NetworkManager *)networkManager{
    SessionProvider *provider = [[SessionProvider alloc]initWithApiManager:manager networkManager:networkManager];
    return provider;
}

- (instancetype)initWithApiManager:(id<ApiProtocol>)manager networkManager:(NetworkManager *)nManager{
    self = [super init];
    if(self){
        operationCounter = 0;
        networkManager = nManager;
        self.actualApiManager = manager;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        operationCounter = 0;
        networkManager = [NetworkManager sharedManager];
        self.settings = [Settings class];
        [self setupActualApiManager];
    }
    return self;
}

- (instancetype)initWithSettings:(Class)settingsClass
{
    self = [super init];
    if (self)
    {
        operationCounter = 0;
        networkManager = [NetworkManager sharedManager];
        self.settings = settingsClass;
        [self setupActualApiManager];
    }
    return self;
}

- (void)loginEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL success,NSError* error))handler{
        if([self.settings domain] && [self.settings domain].length > 0){
            [self authroizeEmail:email withPassword:password completion:^(BOOL authorized, NSError * error) {
                if (error){
                    handler(NO,error);
                    return;
                }
                handler(authorized,nil);
            }];
        }else{
            NSError *error = [[NSError alloc]initWithDomain:@"com.auroraFiles.SessionProvider" code:5000 userInfo:@{}];
            handler(NO,error);
        }
}

- (void)logout:(void (^)(BOOL succsess, NSError *error))handler{
    handler(YES,nil);
    [self.actualApiManager logoutWithCompletion:^(BOOL succsess, NSError *error) {
//        handler(succsess,error);
    }];
}

- (void)checkUserAuthorization:(void (^)(BOOL authorised, BOOL offline, BOOL isP8, NSError *error))handler{
    NSString *scheme = [self.settings domainScheme];
    if (!scheme) {
        [self checkSSLConnection:^(NSString *domain) {
            if(domain && domain.length > 0){
                [self checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline,BOOL isP8,NSError *error){
                    handler(authorised,offline,isP8,error);
                }];
            }else{
                handler(NO, NO, NO, nil);
            }
        }];
    }else{
        if (!self.actualApiManager) {
            [self setupActualApiManager];
        }
        [self checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline,BOOL isP8,NSError *error){
            handler(authorised,offline,isP8,error);
        }];
    }
}

-(void)userData:(void(^)(BOOL authorised, NSError *error))handler{
    if(!self.actualApiManager){
        self.actualApiManager = [networkManager getNetworkManager];
        if (!self.actualApiManager) {
            NSError * error = [NSError errorWithDomain:@"com.auroraFiles.SessionProvider"
                                                  code:999
                                              userInfo:nil];
            handler(NO, error);
            return;
        }
    }
    [self.actualApiManager userData:handler];
}

- (void)cancelAllOperations{
    [self.actualApiManager cancelAllOperations];
}

- (void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline, BOOL isP8, NSError *error))handler
{
    [self.actualApiManager checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline, BOOL isP8,NSError *error) {
        handler(authorised,offline,isP8,error);
    }];
}

- (void)authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL,NSError*))handler
{
    if(!self.actualApiManager){
        self.actualApiManager = [networkManager getNetworkManager];
    }
    [self.actualApiManager authorizeEmail:email withPassword:password completion:handler];
}

- (void)checkWebAuthExistance:(void (^)(BOOL haveWebAuth, NSError *error))handler{
    if(!self.actualApiManager){
        self.actualApiManager = [networkManager getNetworkManager];
    }
    [self.actualApiManager getWebAuthExistanceCompletionHandler:handler];
}

- (void)checkSSLConnection:(void (^)(NSString *))handler{
    if ([_settings domainScheme] && [_settings domain]) {
        handler([_settings domain]);
        return;
    }
    [self checkDomainVersion:^(NSString *domainVersion, NSString *correctHostURL) {
        if (domainVersion && correctHostURL) {
            [self saveDomainVersion:domainVersion domainCorrectHostUrl:correctHostURL];
        }else{
            [self clearDomainInfo];
        }
        handler(correctHostURL);
    }];
}

- (void)checkDomainVersion:(void(^)(NSString *domainVersion, NSString *correctHostURL))handler{
    [[NetworkManager sharedManager] prepareForCheck];
    [[NetworkManager sharedManager] checkDomainVersionAndSSLConnection:^(NSString *domainVersion, NSString *correctHostURL) {
        handler(domainVersion,correctHostURL);
    }];
}

- (void)updateDomainVersion:(void(^)())completionHandler{
    [self checkDomainVersion:^(NSString *domainVersion, NSString *correctHostURL) {
        if (domainVersion && correctHostURL) {
            [self saveDomainVersion:domainVersion domainCorrectHostUrl:correctHostURL];
        }else{
            [self clearDomainInfo];
        }
        completionHandler();
    }];
}

- (void)saveDomainVersion:(NSString *)domainVersion domainCorrectHostUrl:(NSString *)correctURL{
    if (domainVersion) {
        if (![[self.settings lastLoginServerVersion] isEqualToString:domainVersion]) {
            [[StorageManager sharedManager]deleteAllObjects:@"Folder"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.settings setLastLoginServerVersion:domainVersion];
        });
        
        self.actualApiManager =  [networkManager getNetworkManager];
    }
    DDLogInfo(@"ℹ️ host version is %@",[self.settings lastLoginServerVersion]);
    DDLogInfo(@"ℹ️ host is %@",[self.settings domain]);
}

-(void)setupActualApiManager{
    if ([self.settings lastLoginServerVersion]) {
        self.actualApiManager = [networkManager getNetworkManager];
    }
}

-(void)clearDomainInfo{
    [self.settings setDomainScheme:nil];
}


-(void)clear{
    [self cancelAllOperations];
    self.actualApiManager = nil;
}

@end

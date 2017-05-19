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
#import "ApiProtocol.h"
#import "NetworkManager.h"

@interface SessionProvider(){
    int operationCounter;
    NetworkManager *networkManager;
}

@property (nonatomic, strong) id<ApiProtocol> actualApiManager; //
@end
@implementation SessionProvider

+ (instancetype)sharedManager
{
    static SessionProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SessionProvider alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        operationCounter = 0;
        networkManager = [NetworkManager sharedManager];
        [self setupActualApiManager];
    }
    return self;
}

- (void)loginEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL success,NSError* error))handler{
        if([Settings domain] && [Settings domain].length > 0){
            [self authroizeEmail:email withPassword:password completion:^(BOOL authorized, NSError * error) {
                if (authorized)
                {
                    handler(authorized,nil);
                }
                else
                {
                    NSError *error = [[NSError alloc]initWithDomain:@"" code:401 userInfo:@{}];
                    handler(NO,error);
                }
            }];
            
        }else{
            NSError *error = [[NSError alloc]initWithDomain:@"" code:500 userInfo:@{}];
            handler(NO,error);
        }
}

- (void)logout:(void (^)(BOOL succsess, NSError *error))handler{
    [self checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline,BOOL isP8){
        [self.actualApiManager logoutWithCompletion:^(BOOL succsess, NSError *error) {
            handler(succsess,error);
        }];
    }];
}

- (void)checkUserAuthorization:(void (^)(BOOL authorised, BOOL offline, BOOL isP8 ))handler{
    NSString *scheme = [Settings domainScheme];
    if (!scheme) {
        [self checkSSLConnection:^(NSString *domain) {
            if(domain && domain.length > 0){
                [self checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline,BOOL isP8){
                    handler(authorised,offline,isP8);
                }];
            }else{
                handler(NO, NO, NO);
            }
        }];
    }else{
        if (!self.actualApiManager) {
            [self setupActualApiManager];
        }
        [self checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline,BOOL isP8){
            handler(authorised,offline,isP8);
        }];
    }
}

- (void)cancelAllOperations{
    [self.actualApiManager cancelAllOperations];
}

- (void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline, BOOL isP8 ))handler
{
    [self.actualApiManager checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline, BOOL isP8) {
        handler(authorised,offline,isP8);
    }];
}

- (void)authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL,NSError*))handler
{
    [self.actualApiManager authroizeEmail:email withPassword:password completion:^(BOOL success, NSError *error) {
        handler(success,error);
    }];
}

- (void)checkSSLConnection:(void (^)(NSString *))handler{
    if ([Settings domainScheme] && [Settings domain]) {
        handler([Settings domain]);
        return;
    }
    [[NetworkManager sharedManager] prepareForCheck];
    [[NetworkManager sharedManager] checkDomainVersionAndSSLConnection:^(NSString *domainVersion, NSString *correctHostURL) {
        if (domainVersion && correctHostURL) {
            [self saveDomainVersion:domainVersion domainCorrectHostUrl:correctHostURL];
        }else{
            [self clearDomainInfo];
        }
        handler(correctHostURL);
    }];
}

- (void)saveDomainVersion:(NSString *)domainVersion domainCorrectHostUrl:(NSString *)correctURL{
    if (domainVersion) {
        if (![[Settings version] isEqualToString:domainVersion]) {
            [[StorageManager sharedManager]deleteAllObjects:@"Folder"];
        }
        [Settings setLastLoginServerVersion:domainVersion];
        self.actualApiManager =  [networkManager getNetworkManager];
    }
    DDLogInfo(@"ℹ️ host version is %@",[Settings version]);
    DDLogInfo(@"ℹ️ host is %@",[Settings domain]);
}

-(void)setupActualApiManager{
    if ([Settings version]) {
        self.actualApiManager = [networkManager getNetworkManager];
    }
}

-(void)clearDomainInfo{
    [Settings setDomainScheme:nil];
}


-(void)clear{
    [self cancelAllOperations];
    self.actualApiManager = nil;
}

@end

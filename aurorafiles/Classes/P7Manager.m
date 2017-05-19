//
//  P7Manager.m
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "P7Manager.h"
#import "ApiP7.h"
#import "Settings.h"
#import "SessionProvider.h"

@interface P7Manager(){
    
}

@property (nonatomic, strong) ApiP7 * apiManager;

@end

@implementation P7Manager

- (instancetype)init
{
    self = [super init];
    if (self) {
        DDLogInfo(@"P7 API Used");
        self.apiManager = [ApiP7 sharedInstance];
    }
    return self;
}

#pragma mark - User Operations

-(void)authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL, NSError *))handler{
    [self.apiManager getAppDataCompletionHandler:^(NSDictionary *result, NSError *error) {
        if (error)
        {
            handler (NO,error);
            return ;
        }
        NSNumber *loginFormType = [NSNumber new];
        if ([[result valueForKeyPath:@"Result.Token"] isKindOfClass:[NSString class]]) {
            [Settings setToken:[result valueForKeyPath:@"Result.Token"]];
        }
        if ([[result valueForKeyPath:@"Result.App.LoginFormType"] isKindOfClass:[NSNumber class]]) {
            loginFormType = [result valueForKeyPath:@"Result.App.LoginFormType"];
        }
        [self.apiManager signInWithEmail:email andPassword:password loginType:[loginFormType stringValue] completion:^(NSDictionary *result, NSError *error) {
            if([[result valueForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]){
                NSNumber *errorCode = result[@"ErrorCode"];
                if (errorCode.intValue == 101 || errorCode.intValue == 103 || errorCode.intValue == 102 ) {
                    NSString * email = [Settings login];
                    NSString * password = [Settings password];
                    if (email.length && password.length)
                    {
                        [self authroizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error){
                            handler(isAuthorised,error);
                        }];
                        return;
                    }else{
                        handler(NO,error);
                        return;
                    }
                }
                
            }else{
                
            }
            if (error)
            {
                handler(NO,error);
                return;
            }
            handler(YES,error);
        }];
    }];
}
-(void)checkAuthorizeWithCompletion:(void (^)(BOOL, BOOL, BOOL))handler{
    [self.apiManager checkIsAccountAuthorisedWithCompletion:^(NSDictionary *data, NSError *error) {
        if (!error)
        {
            if ([[data valueForKey:@"Result"] isKindOfClass:[NSDictionary class]])
            {
                if (data[@"Result"][@"offlineMod"]) {
                    handler (YES,YES, NO);
                }
                handler (YES,NO,NO);
            }
            else
            {
                if([[data valueForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]){
                    NSNumber *errorCode = data[@"ErrorCode"];
                    if (errorCode.intValue == 101 || errorCode.intValue == 103 || errorCode.integerValue == 102) {
                        NSString * email = [Settings login];
                        NSString * password = [Settings password];
                        if (email.length && password.length)
                        {
                            [self authroizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error){
                                handler(isAuthorised,NO, NO);
                            }];
                            return;
                        }else{
                            handler(NO,NO, NO);
                            return;
                        }
                    }
                    
                }
                else
                {
                    handler(NO,NO, NO);
                }
            }
            return ;
        }
        else
        {
            NSString * email = [Settings login];
            NSString * password = [Settings password];
            if (email.length && password.length)
            {
                [self authroizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error){
                    handler(isAuthorised,NO, NO);
                }];
                return;
            }
            else
            {
                handler (NO,NO, NO);
                return;
            }
        }
    }];
}
-(void)logoutWithCompletion:(void (^)(BOOL, NSError *))handler{
    handler(YES, nil);
}
#pragma mark - Files Operations
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL))complitionHandler{
    [self.apiManager createFolderWithName:name isCorporate:corporate andPath:path ? path : @"" completion:^(NSDictionary * result){
        if ([[result objectForKey:@"Result"]boolValue]) {
            complitionHandler([[result objectForKey:@"Result"]boolValue]);
        }
    }];
}
- (void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL))complitionHandler{
    [self.apiManager renameFolderFromName:name toName:newName isCorporate:[type isEqualToString:@"corporate"] atPath:path isLink:isLink completion:^(NSDictionary* handler){
        if ([[handler objectForKey:@"Result"]boolValue]) {
            complitionHandler(YES);
        }else{
            complitionHandler(NO);
        }
    }];
}

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary * result))complitionHandler{
    
    
    [self.apiManager renameFolderFromName:name toName:newName isCorporate:[type isEqualToString:@"corporate"] atPath:path isLink:isLink  completion:^(NSDictionary* result) {
        if ([[result objectForKey:@"Result"]boolValue]){
            [self.apiManager getFolderInfoForName:newName path:path type:type completion:^(NSDictionary * result) {
                if ([[result objectForKey:@"Result"] isKindOfClass:[NSDictionary class]]){
                    NSDictionary *folderRef = [result objectForKey:@"Result"];
                    complitionHandler(folderRef);
                }
                else{
                    complitionHandler(nil);
                }
                
            }];
        }
        else{
            complitionHandler(nil);
        }
    }];
}

-(void)checkItemExistanceonServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL))complitionHandler{
    [self.apiManager getFolderInfoForName:name path:path type:type completion:^(NSDictionary *result) {
        if ([[result valueForKey:@"Result"]isKindOfClass:[NSNumber class]] && ![[result valueForKey:@"Result"]boolValue]) {
            complitionHandler(NO);
        }else{
            id resultObj = [result valueForKey:@"Result"];
            if ([resultObj isKindOfClass:[NSNull class]]) {
                complitionHandler(NO);
                return;
            }
            complitionHandler(YES);
        }
    }];
}

-(void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *))complitionHandler{
    [self.apiManager getFilesForFolder:folderPath withType:type completion:^(NSDictionary * result) {
        NSArray * items;
        if (result && [result isKindOfClass:[NSDictionary class]] && [[result objectForKey:@"Result"] isKindOfClass:[NSDictionary class]])
        {
            items = [[[result objectForKey:@"Result"] objectForKey:@"Items"] isKindOfClass:[NSArray class]] ? [[result objectForKey:@"Result"] objectForKey:@"Items"] : @[];
        }
        else
        {
            items = @[];
        }
        complitionHandler(items);
    }];
}
#pragma mark - Helpers

-(void)checkConnection:(void (^)(BOOL, NSError *, NSString *, id<ApiProtocol>))complitionHandler{
    [self.apiManager getAppDataCompletionHandler:^(NSDictionary *data, NSError *error) {
        if (error) {
            complitionHandler(NO,error,nil,self);
        }
        if (data) {
            complitionHandler(YES,nil,@"P7",self);
        }else{
            complitionHandler(NO,nil,nil,self);
        }
    }];
}

- (void)getPublicLinkForFileNamed:(NSString *)name filePath:(NSString *)filePath type:(NSString *)type size:(NSString *)size isFolder:(BOOL)isFolder completion:(void (^)(NSString *))completionHandler{
    [self.apiManager getPublicLinkForFileNamed:name filePath:filePath type:type size:size isFolder:isFolder completion:^(NSString *publicLink) {
        completionHandler(publicLink);
    }];
}

-(void)cancelAllOperations{
    [self.apiManager cancelAllOperations];
}

-(void)stopFileThumb:(NSString *)folderName{
    
}

@end

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

-(void)authorizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL success, NSError *error))handler{
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
                        [self authorizeEmail:email withPassword:password completion:^(BOOL isAuthorised, NSError *error) {
                            handler(isAuthorised, error);
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
                            [self authorizeEmail:email withPassword:password completion:^(BOOL success, NSError *error) {
                                handler(success,NO, NO);
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
                [self authorizeEmail:email withPassword:password completion:^(BOOL success, NSError *error) {
                    handler(success,NO, NO);
                }];                            [self authorizeEmail:email withPassword:password completion:^(BOOL success, NSError *error) {
                    handler(success,NO, NO);
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
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [self.apiManager createFolderWithName:name isCorporate:corporate andPath:path ? path : @"" completion:^(NSDictionary* data, NSError* error){
        if ([[data objectForKey:@"Result"]boolValue]) {
            complitionHandler([[data objectForKey:@"Result"]boolValue],error);
        }
    }];
}
- (void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [self.apiManager renameFolderFromName:name toName:newName isCorporate:[type isEqualToString:@"corporate"] atPath:path isLink:isLink completion:^(NSDictionary* data, NSError* error){
        if ([[data objectForKey:@"Result"]boolValue]) {
            complitionHandler(YES,nil);
        }else{
            complitionHandler(NO,error);
        }
    }];
}

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *result, NSError *error))complitionHandler{
    
    
    [self.apiManager renameFolderFromName:name toName:newName isCorporate:[type isEqualToString:@"corporate"] atPath:path isLink:isLink  completion:^(NSDictionary* data, NSError* error) {
        if ([[data objectForKey:@"Result"]boolValue]){
            [self.apiManager getFolderInfoForName:newName path:path type:type completion:^(NSDictionary* data, NSError* error) {
                if ([[data objectForKey:@"Result"] isKindOfClass:[NSDictionary class]]){
                    NSDictionary *folderRef = [data objectForKey:@"Result"];
                    complitionHandler(folderRef,nil);
                }
                else{
                    complitionHandler(nil,error);
                }
                
            }];
        }
        else{
            complitionHandler(nil,error);
        }
    }];
}

-(void)checkItemExistenceOnServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist, NSError *error))complitionHandler{
    [self.apiManager getFolderInfoForName:name path:path type:type completion:^(NSDictionary* data, NSError* error) {
        if ([[data valueForKey:@"Result"]isKindOfClass:[NSNumber class]] && ![[data valueForKey:@"Result"]boolValue]) {
            complitionHandler(NO,error);
        }else{
            id resultObj = [data valueForKey:@"Result"];
            if ([resultObj isKindOfClass:[NSNull class]]) {
                complitionHandler(NO,error);
                return;
            }
            complitionHandler(YES,nil);
        }
    }];
}

-(void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *items, NSError *error))complitionHandler{
    [self.apiManager getFilesForFolder:folderPath withType:type completion:^(NSDictionary* data, NSError* error) {
        if(error){
            complitionHandler(@[],error);
            return;
        }
        NSArray * items;
        if (data && [data isKindOfClass:[NSDictionary class]] && [[data objectForKey:@"Result"] isKindOfClass:[NSDictionary class]])
        {
            items = [[[data objectForKey:@"Result"] objectForKey:@"Items"] isKindOfClass:[NSArray class]] ? [[data objectForKey:@"Result"] objectForKey:@"Items"] : @[];
        }
        else
        {
            items = @[];
        }
        complitionHandler(items,nil);
    }];
}

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [self.apiManager deleteFile:folder isCorporate:corporate completion:complitionHandler];
}

- (void)deleteFiles:(NSArray<Folder *> *)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [self.apiManager deleteFiles:files isCorporate:corporate completion:complitionHandler];
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

- (void)getPublicLinkForFileNamed:(NSString *)name filePath:(NSString *)filePath type:(NSString *)type size:(NSString *)size isFolder:(BOOL)isFolder completion:(void (^)(NSString *publicLink, NSError *error))completionHandler{
    [self.apiManager getPublicLinkForFileNamed:name filePath:filePath type:type size:size isFolder:isFolder completion:^(NSString *publicLink, NSError* error) {
        if(error){
            completionHandler(nil,error);
            return;;
        }
        completionHandler(publicLink,nil);
    }];
}

-(void)cancelAllOperations{
    [self.apiManager cancelAllOperations];
}

-(void)stopFileThumb:(NSString *)folderName{
    
}

@end

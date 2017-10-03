//
//  P8Manager.m
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "P8Manager.h"
#import "ApiP8.h"
#import "Settings.h"

@interface P8Manager (){
    
}

@end

@implementation P8Manager

- (instancetype)init
{
    self = [super init];
    if (self) {
        DDLogInfo(@"P8 API Used");
    }
    return self;
}

#pragma mark - User Operations

-(void)authorizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL success, NSError *error))handler{
    [[ApiP8 coreModule] signInWithEmail:email andPassword:password completion:^(NSDictionary *data, NSError *error) {
        if (error)
        {
            handler(NO,error);
            return;
        }
        handler(YES,error);
        return;
    }];
}
-(void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline, BOOL isP8, NSError *error))handler{
    [[ApiP8 coreModule] getUserWithCompletion:^(NSString *publicID, NSError *error) {
        if(error){
            handler(NO,NO,YES,error);
            return;
        }

        if ([publicID isEqualToString:[Settings login]]) {
            handler(YES,NO,YES,nil);
        }else{
            NSString * email = [Settings login];
            NSString * password = [Settings password];
            if (email.length && password.length)
            {
                [[ApiP8 coreModule] signInWithEmail:email andPassword:password completion:^(NSDictionary *data, NSError *error) {
                    if (error)
                    {
                        handler(NO,NO,YES,error);
                        return;
                    }
                    handler(YES,NO,YES,nil);
                }];
            }else{
                handler(NO,NO,YES,nil);
            }
        }
    }];
}

- (void)userData:(void (^)(BOOL isAuthorized, NSError *error))handler{
    [[ApiP8 coreModule] getUserWithCompletion:^(NSString *publicID, NSError *error) {
        if (error){
            handler(NO, error);
            return;
        }
        if ([publicID isEqualToString:[Settings login]]){
            handler(YES, nil);
            return;
        }else{
            handler(NO, nil);
            return;
        }
    }];
}

-(void)logoutWithCompletion:(void (^)(BOOL, NSError *))handler{
    [[ApiP8 coreModule]logoutWithCompletion:^(BOOL succsess, NSError *error) {
        handler(succsess, error);
    }];
}

#pragma mark - Files Operations

- (void)findFilesWithPattern:(NSString *)searchPattern type:(NSString *)type completion:(void (^)(NSArray *, NSError *))completionHandler{
    [[ApiP8 filesModule]searchFilesInSection:type pattern:searchPattern completion:^(NSArray *result, NSError *error) {
        completionHandler(result,error);
    }];
}

-(void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [[ApiP8 filesModule]createFolderWithName:name isCorporate:corporate andPath:path completion:^(BOOL result, NSError *error) {
        complitionHandler(result,error);
    }];
}
-(void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [[ApiP8 filesModule]renameFolderFromName:name toName:newName type:type atPath:path isLink:isLink completion:^(BOOL success, NSError *error) {
        if (success) {
            complitionHandler(YES,nil);
        }else{
            complitionHandler(NO,error);
        }
    }];
}

-(void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *result, NSError *error))complitionHandler{
    
    [[ApiP8 filesModule]renameFolderFromName:name toName:newName type:type atPath:path isLink:isLink  completion:^(BOOL success, NSError *error) {
        if (success) {
            [[ApiP8 filesModule]getFileInfoForName:newName path:path corporate:type completion:^(NSDictionary *result, NSError *error) {
                if(error){
                    complitionHandler(nil,error);
                }else{
                    complitionHandler(result,nil);
                }
            }];
        }else{
            complitionHandler(nil,error);
        }
    }];
}

-(void)checkItemExistenceOnServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist, NSError *error))complitionHandler{
    [[ApiP8 filesModule]getFileInfoForName:name path:path corporate:type completion:^(NSDictionary *result, NSError *error) {
        complitionHandler(result,error);
    }];
}
-(void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *items, NSError *error))complitionHandler{
    [[ApiP8 filesModule] prepareForThumbUpdate];
    [[ApiP8 filesModule]getFilesForFolder:folderPath withType:type completion:^(NSArray *items, NSError * error){
        if (error){
            complitionHandler(nil,error);
        }else{
            if (items.count>0) {
//                [[ApiP8 filesModule]getThumbnailsForFiles:items withCompletion:^(NSArray *resultedItems) {
                    complitionHandler(items,nil);
//                }];
            }else{
                complitionHandler(@[],error);
            }
        }

    }];

}

- (void)getPublicLinkForFileNamed:(NSString *)name filePath:(NSString *)filePath type:(NSString *)type size:(NSString *)size isFolder:(BOOL)isFolder completion:(void (^)(NSString *publicLink, NSError *error))completionHandler{
    [[ApiP8 filesModule]getPublicLinkForFileNamed:name filePath:filePath type:type size:size isFolder:isFolder completion:^(NSString *publicLink, NSError *error) {
        completionHandler(publicLink,error);
    }];
}

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [[ApiP8 filesModule]deleteFile:folder isCorporate:corporate completion:complitionHandler];
}

- (void)deleteFiles:(NSArray<Folder *> *)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [[ApiP8 filesModule]deleteFiles:files isCorporate:corporate completion:complitionHandler];
}
#pragma mark - Helpers

-(void)getWebAuthExistanceCompletionHandler:(void (^)(BOOL, NSError *))handler{
    [[ApiP8 coreModule] getWebAuthExistanceCompletionHandler:handler];
}

-(void)checkConnection:(void (^)(BOOL, NSError *, NSString *, id<ApiProtocol>))complitionHandler{
    [[ApiP8 coreModule]pingHostWithCompletion:^(BOOL isP8, NSError *error) {
        
        if (error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
                complitionHandler(NO,error,nil,self);
//            });
        }
        if (isP8) {
//            dispatch_async(dispatch_get_main_queue(), ^{
                complitionHandler(YES,nil,@"P8",self);
//            });
            
        }else{
//            dispatch_async(dispatch_get_main_queue(), ^{
                 complitionHandler(NO,nil,nil,self);
//            });
           
        }
    }];
}

-(void)cancelAllOperations{
    [ApiP8 cancelAllOperations];
}

-(void)stopFileThumb:(NSString *)folderName{
    [[ApiP8 filesModule]stopFileThumb:folderName];
}

- (NSString *)managerName{
    return @"P8 manager";
}
@end

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
        NSLog(@"P8 API Used");
    }
    return self;
}

#pragma mark - User Operations

-(void)authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL, NSError *))handler{
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
-(void)checkAuthorizeWithCompletion:(void (^)(BOOL, BOOL, BOOL))handler{
    [[ApiP8 coreModule] getUserWithCompletion:^(NSString *publicID, NSError *error) {
        if ([publicID isEqualToString:[Settings login]]) {
            handler(YES,NO,YES);
        }else{
            NSString * email = [Settings login];
            NSString * password = [Settings password];
            if (email.length && password.length)
            {
                [[ApiP8 coreModule] signInWithEmail:email andPassword:password completion:^(NSDictionary *data, NSError *error) {
                    if (error)
                    {
                        handler(NO,error,YES);
                        return;
                    }
                    handler(YES,NO,YES);
                }];
            }else{
                handler(NO,NO,YES);
            }
        }
    }];

}
-(void)logoutWithCompletion:(void (^)(BOOL, NSError *))handler{
    [[ApiP8 coreModule]logoutWithCompletion:^(BOOL succsess, NSError *error) {
        handler(succsess, error);
    }];
}

#pragma mark - Files Operations
-(void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL))complitionHandler{
    [[ApiP8 filesModule]createFolderWithName:name isCorporate:corporate andPath:path completion:^(BOOL result) {
        complitionHandler(result);
    }];
}
-(void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL))complitionHandler{
    [[ApiP8 filesModule]renameFolderFromName:name toName:newName type:type atPath:path isLink:isLink completion:^(BOOL success) {
        if (success) {
            complitionHandler(YES);
        }else{
            complitionHandler(NO);
        }
    }];
}

-(void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *))complitionHandler{
    
    [[ApiP8 filesModule]renameFolderFromName:name toName:newName type:type atPath:path isLink:isLink  completion:^(BOOL success) {
        if (success) {
            [[ApiP8 filesModule]getFileInfoForName:newName path:path corporate:type completion:^(NSDictionary *result) {
                complitionHandler(result);
            }];
        }else{
            complitionHandler(nil);
        }
    }];
}

-(void)checkItemExistanceonServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL))complitionHandler{
    [[ApiP8 filesModule]getFileInfoForName:name path:path corporate:type completion:^(NSDictionary *result) {
        complitionHandler(result);
    }];
}
-(void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *))complitionHandler{
    [[ApiP8 filesModule]getFilesForFolder:folderPath withType:type completion:^(NSArray *items){
        if (items.count>0) {
            [[ApiP8 filesModule]getThumbnailsForFiles:items withCompletion:^(NSArray *resultedItems) {
                complitionHandler(resultedItems);
            }];
        }else{
            complitionHandler(@[]);
        }
    }];

}
#pragma mark - Helpers

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

@end

//
//  ApiProtocol.h
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ApiProtocol <NSObject>

- (instancetype)init;

#pragma mark - User Operations
- (void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline, BOOL isP8 ))handler;
- (void)authroizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL success,NSError* error))handler;
- (void)logoutWithCompletion:(void (^)(BOOL succsess, NSError *error))handler;
#pragma mark - Files Operations
- (void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *items))complitionHandler;
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success))complitionHandler;
- (void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success))complitionHandler;
- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary * result))complitionHandler;
- (void)checkItemExistanceonServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist))complitionHandler;
- (void)getPublicLinkForFileNamed:(NSString *)name filePath:(NSString *)filePath type:(NSString *)type size:(NSString *)size isFolder:(BOOL)isFolder completion:(void (^)(NSString *publicLink))completionHandler;
#pragma mark - Helpers
- (void)checkConnection:(void (^)(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager))complitionHandler;
- (void)stopFileThumb:(NSString *)folderName;
- (void)cancelAllOperations;

@end



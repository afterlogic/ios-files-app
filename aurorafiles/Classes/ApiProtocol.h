//
//  ApiProtocol.h
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Folder.h"

@protocol ApiProtocol <NSObject>

- (instancetype)init;

#pragma mark - User Operations
- (void)checkAuthorizeWithCompletion:(void (^)(BOOL authorised, BOOL offline, BOOL isP8, NSError *error))handler;
- (void)authorizeEmail:(NSString *)email withPassword:(NSString *)password completion:(void (^)(BOOL success,NSError* error))handler;
- (void)userData:(void(^)(BOOL authorised, NSError *error))handler;
- (void)logoutWithCompletion:(void (^)(BOOL succsess, NSError *error))handler;

#pragma mark - Auth Operations
- (void)getWebAuthExistanceCompletionHandler:(void (^)(BOOL haveWebAuth, NSError * error)) handler;

#pragma mark - Files Operations
- (void)findFilesWithPattern:(NSString *)searchPattern type:(NSString *)type completion:(void(^)(NSArray *items, NSError *error))completionHandler;
- (void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *items, NSError *error))completionHandler;
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success, NSError *error))completionHandler;
- (void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success, NSError *error))completionHandler;
- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *result, NSError *error))completionHandler;
- (void)checkItemExistenceOnServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist, NSError *error))completionHandler;

- (void)getPublicLinkForFileNamed:(NSString *)name filePath:(NSString *)filePath type:(NSString *)type size:(NSString *)size isFolder:(BOOL)isFolder completion:(void (^)(NSString *publicLink, NSError *error))completionHandler;

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(BOOL success, NSError *error))completionHandler;
- (void)deleteFiles:(NSArray<Folder *> *)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL success, NSError *error))completionHandler;

#pragma mark - Helpers
- (void)checkConnection:(void (^)(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager))completionHandler;
- (void)stopFileThumb:(NSString *)folderName;
- (void)cancelAllOperations;

@end



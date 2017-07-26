//
//  IFileNetworkOperations.h
//  aurorafiles
//
//  Created by Cheshire on 02.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Folder.h"

@protocol IFileOperationsProtocol <NSObject>

+ (instancetype)sharedProvider;
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success, NSError *error))complitionHandler;
- (void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success, NSError *error))handler;
- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *result, NSError *error))handler;
- (void)checkItemExistanceOnServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist, NSError *error))complitionHandler;
- (void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *items, NSError *error))complitionHandler;
- (void)findFilesUsingPattern:(NSString *)searchPattern withType:(NSString *)type completion:(void (^)(NSArray *items, NSError *error))complitionHandler;
- (void)stopDownloadigThumbForFile:(NSString *)fileName;

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(BOOL, NSError *error))complitionHandler;
- (void)deleteFiles:(NSArray<Folder *> *)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL, NSError *error))complitionHandler;

- (void)clearNetworkManager;

@end

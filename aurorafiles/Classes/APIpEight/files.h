//
//  files.h
//  aurorafiles
//
//  Created by Cheshire on 19.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//
typedef void (^UploadProgressBlock)(float progress);
#import <Foundation/Foundation.h>
#import "AuroraModuleProtocol.h"
#import "Folder.h"
@interface files : NSObject <AuroraModuleProtocol>
- (NSString *)moduleName;
- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type completion:(void (^)(NSArray *items, NSError * error))handler;
- (void)searchFilesInFolder:(NSString *)folderName withType:(NSString *)type fileName:(NSString *)fileName completion:(void (^)(NSArray *items, NSError *error))handler;
- (void)searchFilesInSection:(NSString *)type pattern:(NSString *)searchPattern completion:(void (^)(NSArray *, NSError *))handler;
- (void)prepareForThumbUpdate;
- (void)getThumbnailsForFiles:(NSArray <NSMutableDictionary *> *)files withCompletion:(void (^)(NSArray *resultedItems))handler;
- (void)getThumbnailForFileNamed:(NSString *)folderName type:(NSString *)type path:(NSString *)parentPath withCompletion:(void (^)(NSString *thumbnail, NSError *error))handler;
- (void)stopFileThumb:(NSString *)folderName;

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success, NSError *error))handler;

- (void)getFileInfoForName:(NSString *)name path:(NSString *)path corporate:(NSString *)type completion:(void (^)(NSDictionary *result, NSError *error))handler;

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL result, NSError *error))handler;
- (void)uploadFile:(NSData *)file mime:(NSString *)mime toFolderPath:(NSString *)path withName:(NSString *)name isCorporate:(BOOL)corporate uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock completion:(void (^)(BOOL result, NSError *error))handler;
- (void)getFileView:(Folder *)folder type:(NSString *)type withProgress:(void (^)(float progress))progressBlock withCompletion:(void (^)(NSString *thumbnail))handler;

- (void)getPublicLinkForFileNamed:(NSString *)name filePath:(NSString *)filePath type:(NSString *)type size:(NSString *)size isFolder:(BOOL)isFolder completion:(void (^)(NSString *publicLink, NSError *error))completion;

- (void)deleteFile:(Folder *)file isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess, NSError *error))handler;
- (void)deleteFiles:(NSArray<Folder *> *)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess, NSError *error))handler;

- (NSString *)getExistedThumbnailForFile:(Folder *)folder;
@end

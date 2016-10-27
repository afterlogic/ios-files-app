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
- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type completion:(void (^)(NSArray *items))handler;
- (void)searchFilesInFolder:(NSString *)folderName withType:(NSString *)type fileName:(NSString *)fileName completion:(void (^)(NSArray *items))handler;

- (void)getUserFilestorageQoutaWithCompletion:(void(^)(NSString *publicID, NSError *error))handler;

- (void)getThumbnailsForFiles:(NSArray <Folder *>*)files withCompletion:(void(^)(bool success))handler;
- (void)getFileThumbnail:(NSString *)folderName type:(NSString *)type path:(NSString *)path withCompletion:(void(^)(NSString *thumbnail))handler;
- (void)stopFileThumb:(NSString *)folderName;

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success))handler;

- (void)getFileInfoForName:(NSString *)name path:(NSString *)path corporate:(BOOL)corporate completion:(void (^)(NSDictionary *result))handler;

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL result))handler;
- (void)uploadFile:(NSData *)file mime:(NSString *)mime toFolderPath:(NSString *)path withName:(NSString *)name isCorporate:(BOOL)corporate uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock completion:(void (^)(NSDictionary *response))handler;
- (void)getFileView:(Folder *)folder type:(NSString *)type withProgress:(void (^)(float progress))progressBlock withCompletion:(void(^)(NSString *thumbnail))handler;


- (void)deleteFile:(Folder *)file isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess))handler;
- (void)deleteFiles:(NSArray<Folder *>*)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess))handler;

- (NSString *)getExistedFile:(Folder *)folder;
- (NSString *)getExistedThumbnailForFile:(Folder *)folder;
@end

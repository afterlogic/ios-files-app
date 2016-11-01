//
//  API.h
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^UploadProgressBlock)(float progress);

@class Folder;
@interface API : NSObject

+ (instancetype) sharedInstance;

- (void)getAppDataCompletionHandler:(void (^)(NSDictionary* data, NSError* error)) handler;

- (void)signInWithEmail:(NSString *)email andPassword:(NSString *)password  loginType:(NSString *) type completion:(void (^)(NSDictionary *data, NSError *error))handler;

- (void)checkIsAccountAuthorisedWithCompletion:(void (^)(NSDictionary *data, NSError *error)) handler;

- (void)getFilesForFolder:(NSString*)folderName withType:(NSString*)type completion:(void (^)(NSDictionary *data)) handler;

- (void)deleteFiles:(NSDictionary*)files isCorporate:(BOOL)corporate completion: (void (^)(NSDictionary* data)) handler;

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(NSDictionary *))handler;

- (void)createFolderWithName:(NSString*)name isCorporate:(BOOL)corporate andPath:(NSString*)path completion:(void (^)(NSDictionary*))handler;

- (void)renameFolderFromName:(NSString*)name toName:(NSString*)newName isCorporate:(BOOL)corporate atPath:(NSString*)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary*))handler;
- (void)getFolderInfoForName:(NSString*)name path:(NSString*)path type:(NSString*)type completion:(void (^)(NSDictionary*))handler;
- (void)putFile:(NSData *)file toFolderPath:(NSString *)folderPath withName:(NSString *)name uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock completion:(void (^)(NSDictionary *))handler;

- (void)cancelAllOperations;

@end

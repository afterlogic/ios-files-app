//
//  files.h
//  aurorafiles
//
//  Created by Cheshire on 19.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuroraModuleProtocol.h"
@interface files : NSObject <AuroraModuleProtocol>
- (NSString *)moduleName;
- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type completion:(void (^)(NSArray *items))handler;
- (void)searchFilesInFolder:(NSString *)folderName withType:(NSString *)type fileName:(NSString *)fileName completion:(void (^)(NSArray *items))handler;

- (void)getUserFilestorageQoutaWithCompletion:(void(^)(NSString *publicID, NSError *error))handler;

- (void)getFileThumbnail:(NSString *)folderName type:(NSString *)type path:(NSString *)path withCompletion:(void(^)(NSString *thumbnail))handler;
- (void)stopFileThumb:(NSString *)folderName;

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success))handler;
@end

//
//  StorageManager.h
//  aurorafiles
//
//  Created by Michael Akopyants on 15/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import "IFileOperationsProtocol.h"
#import "IDataBaseProtocol.h"
#import "Folder.h"

@interface StorageManager : NSObject

@property (readonly,strong, nonatomic) id<IDataBaseProtocol>DBProvider;

+ (instancetype)sharedManager;

- (void)setupDBProvider:(id<IDataBaseProtocol>)provider;
- (void)setupFileOperationsProvider:(id<IFileOperationsProtocol>)provider;

- (void)renameFolder:(Folder*)folder toNewName:(NSString*)newName withCompletion:(void (^)(Folder*))handler;
- (void)renameFile:(Folder *)file toNewName:(NSString *)newName withCompletion:(void (^)(Folder* updatedFile))complitionHandler;
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success))complitionHandler;
- (void)checkItemExistanceonServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist))complitionHandler;
- (void)updateFilesWithType:(NSString*)type forFolder:(Folder*)folder withCompletion:(void (^)())handler;
- (void)stopGettingFileThumb:(NSString *)file;
- (void)deleteAllObjects: (NSString *) entityDescription ;
- (void)saveLastUsedFolder:(NSDictionary *)folderSimpleRef;
- (void)getLastUsedFolderWithHandler:(void(^)(NSDictionary *result))complition;
- (Folder *)getFolderWithName:(NSString *)name type:(NSString *)type fullPath:(NSString *)path;
- (void)removeSavedFilesForItem:(Folder *)item;
- (void)deleteItem:(Folder *)item;

- (void)clear;

@end

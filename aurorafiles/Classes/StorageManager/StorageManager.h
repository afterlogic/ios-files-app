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

- (void)renameOperation:(Folder *)file withNewName:(NSString *)newName withCompletion:(void (^)(Folder *updatedFile, NSError *error))complitionHandler;

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success, NSError *error))complitionHandler;
- (void)checkItemExistanceonServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist, NSError *error))complitionHandler;
- (void)updateFilesWithType:(NSString *)type forFolder:(Folder *)folder withCompletion:(void (^)(NSInteger *itemsCount, NSError *error))handler;
- (void)searchFilesUsingPattern:(NSString *)pattern type:(NSString *) type handler:(void(^)(NSInteger itemsCount, NSError *error ))complitionHandler;
- (void)stopGettingFileThumb:(NSString *)file;

- (void)saveLastUsedFolder:(NSDictionary *)folderSimpleRef;
- (void)getLastUsedFolderWithHandler:(void (^)(NSDictionary *result, NSError *error))complition;

- (void)removeSavedFilesForItem:(Folder *)item;

- (void)deleteItem:(Folder *)item controller:(UIViewController *)controller isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess, NSError *error))handler;
- (void)deleteAllObjects: (NSString *) entityDescription;


- (void)clear;

@end

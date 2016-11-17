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
#import "Folder.h"

@interface StorageManager : NSObject

+ (instancetype)sharedManager;

@property (readonly, nonatomic, strong) NSManagedObjectContext * managedObjectContext;
- (void)initCoreData;
- (void)saveContext;

- (void)renameFolder:(Folder*)folder toNewName:(NSString*)newName withCompletion:(void (^)(Folder*))handler;
- (void)renameFile:(Folder *)file toNewName:(NSString *)newName withCompletion:(void (^)(Folder* updatedFile))complitionHandler;
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success))complitionHandler;
- (void)getItemInfoForName:(NSString *)name path:(NSString *)path corporate:(NSString *)type completion:(void (^)(Folder *result))complitionHandler;

- (void)updateFilesWithType:(NSString*)type forFolder:(Folder*)folder withCompletion:(void (^)())handler;
- (void)updateFileThumbnail:(Folder *)file type:(NSString*)type context:(NSManagedObjectContext *) context complition:(void (^)(UIImage* thumbnail))handler;
- (void)stopGettingFileThumb:(NSString *)file;
- (void)deleteAllObjects: (NSString *) entityDescription ;

- (void)saveLastUsedFolder:(Folder *)folder;
- (void)getLastUsedFolderWithHandler:(void(^)(Folder *result))complition; 

- (Folder *)getFolderWithName:(NSString *)name type:(NSString *)type fullPath:(NSString *)path;
- (void)removeSavedFilesForItem:(Folder *)item;
- (void)deleteItem:(Folder *)item;

-(void)removeChildDuplicatesForFolder:(Folder *)folder;

@end

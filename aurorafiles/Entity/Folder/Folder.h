//
//  Folder.h
//  aurorafiles
//
//  Created by Michael Akopyants on 15/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <FastEasyMapping/FastEasyMapping.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum ActionType: int {
    viewActionType,
    downloadActionType,
    listActionType,
    openActionType
}MainActionType;

@interface Folder : NSManagedObject

// Insert code here to declare functionality of your managed object subclass
+ (FEMMapping*)defaultMapping;
+ (FEMMapping*)renameMapping;
+ (FEMMapping*)P8DefaultMapping;
+ (FEMMapping*)P8RenameMapping;
- (BOOL)canEdit;
- (BOOL)isImageContentType;
- (BOOL)isZippedFile;
- (BOOL)isZipArchive;
+ (NSArray*)imageContentTypes;
- (NSString*)embedThumbnailLink;
- (NSString*)viewLink;
- (NSString*)downloadLink;
- (NSString*)urlScheme;
- (NSString*)validContentType;
- (NSURL*)downloadURL;
- (NSDictionary *)folderMOC;

+ (Folder *)createFolderFromRepresentation:(NSDictionary *)itemRef type:(BOOL )isP8 parrentPath:(NSString *)path InContext:(NSManagedObjectContext *) context;
+ (NSFetchRequest *)getFetchRequestInContext:(NSManagedObjectContext *)context descriptors:(NSArray *)descriptors predicate:(NSPredicate *)predicate;
+ (NSArray *)fetchFoldersInContext:(NSManagedObjectContext *)context descriptors:(NSArray *)descriptors predicate:(NSPredicate *)predicate;
+ (Folder *)findObjectByItemRef:(NSDictionary *)itemRef context:(NSManagedObjectContext *)ctx;

+ (NSString *)getExistedFile:(Folder *)folder;
@end

NS_ASSUME_NONNULL_END

#import "Folder+CoreDataProperties.h"

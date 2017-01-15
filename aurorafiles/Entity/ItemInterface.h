//
// Created by Cheshire on 11.01.17.
// Copyright (c) 2017 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FastEasyMapping.h"

@protocol ItemInterface <NSObject>
//@required
@property (nullable, nonatomic, retain) NSNumber *wasDeleted;
@property (nullable, nonatomic, retain) NSNumber *isLastUsedUploadFolder;
@property (nullable, nonatomic, retain) NSString *downloadedName;
@property (nullable, nonatomic, retain) NSNumber *isDownloaded;
@property (nullable, nonatomic, retain) NSNumber *downloadIdentifier;
@property (nullable, nonatomic, retain) NSNumber *toRemove;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSString *fullpath;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *size;
@property (nullable, nonatomic, retain) NSNumber *isFolder;
@property (nullable, nonatomic, retain) NSNumber *isLink;
@property (nullable, nonatomic, retain) NSString *linkType;
@property (nullable, nonatomic, retain) NSString *linkUrl;
@property (nullable, nonatomic, retain) NSDate *lastModified;
@property (nullable, nonatomic, retain) NSString *contentType;
@property (nullable, nonatomic, retain) NSNumber *iFramed;
@property (nullable, nonatomic, retain) NSNumber *thumb;
@property (nullable, nonatomic, retain) NSString *thumbnailLink;
@property (nullable, nonatomic, retain) NSString *oembedHtml;
@property (nullable, nonatomic, retain) NSString *folderHash;
@property (nullable, nonatomic, retain) NSNumber *isShared;
@property (nullable, nonatomic, retain) NSString *owner;
@property (nullable, nonatomic, retain) NSString *content;
@property (nullable, nonatomic, retain) NSNumber *isExternal;
@property (nullable, nonatomic, retain) NSNumber *isP8;
@property (nullable, nonatomic, retain) NSString *parentPath;
@property (nullable, nonatomic, retain) NSString *mainAction;
//@end

//@protocol ItemMethodsInterface <NSObject>
+ (FEMMapping*)defaultMapping;
+ (FEMMapping*)renameMapping;
+ (FEMMapping*)P8DefaultMapping;
+ (FEMMapping*)P8RenameMapping;
- (BOOL)canEdit;
- (BOOL)isImageContentType;
- (BOOL)isZippedFile;
+ (NSArray*)imageContentTypes;
- (NSString*)embedThumbnailLink;
- (NSString*)viewLink;
- (NSString*)downloadLink;
- (NSString*)urlScheme;
- (NSString*)validContentType;
- (NSURL*)downloadURL;
- (NSDictionary *)folderMOC;

+ (id <ItemInterface> *)createFolderFromRepresentation:(NSDictionary *)itemRef type:(BOOL )isP8 parrentPath:(NSString *)path InContext:(NSManagedObjectContext *) context;
+ (NSFetchRequest *)getFetchRequestInContext:(NSManagedObjectContext *)context descriptors:(NSArray *)descriptors predicate:(NSPredicate *)predicate;
+ (NSArray *)fetchFoldersInContext:(NSManagedObjectContext *)context descriptors:(NSArray *)descriptors predicate:(NSPredicate *)predicate;
+ (id <ItemInterface> *)findObjectByItemRef:(NSDictionary *)itemRef context:(NSManagedObjectContext *)ctx;

+ (NSString *)getExistedFile:(id<ItemInterface> *)folder;

@end
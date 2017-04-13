//
//  Folder+CoreDataProperties.h
//  aurorafiles
//
//  Created by Michael Akopyants on 15/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Folder.h"

NS_ASSUME_NONNULL_BEGIN

@interface Folder (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *prKey;

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

@property (nullable, nonatomic, retain) NSString *thumbnailUrl;
@property (nullable, nonatomic, retain) NSString *viewUrl;
@property (nullable, nonatomic, retain) NSString *downloadedUrl;

@end

@interface Folder (CoreDataGeneratedAccessors)

@end

NS_ASSUME_NONNULL_END

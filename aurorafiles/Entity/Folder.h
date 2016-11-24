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

@interface Folder : NSManagedObject

// Insert code here to declare functionality of your managed object subclass
+ (FEMMapping*)defaultMapping;
+ (FEMMapping*)renameMapping;
+ (FEMMapping*)P8DefaultMapping;
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
@end

NS_ASSUME_NONNULL_END

#import "Folder+CoreDataProperties.h"

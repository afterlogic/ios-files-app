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
- (BOOL)canEdit;
- (BOOL)isImageContentType;
+ (NSArray*)imageContentTypes;
- (NSString*)embedThumbnailLink;
- (NSString*)viewLink;
- (NSString*)downloadLink;
- (NSString*)urlScheme;
- (NSString*)validContentType;
- (NSURL*)downloadURL;
@end

NS_ASSUME_NONNULL_END

#import "Folder+CoreDataProperties.h"

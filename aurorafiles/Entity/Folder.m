//
//  Folder.m
//  aurorafiles
//
//  Created by Michael Akopyants on 15/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "Folder.h"
#import "Settings.h"

@implementation Folder

+ (FEMMapping*)renameMapping
{
    FEMMapping * mapping = [[FEMMapping alloc] initWithEntityName:@"Folder"];
    mapping.primaryKey = @"name";
    
    [mapping addAttributesFromDictionary:@{@"identifier":@"Id"}];
    [mapping addAttributesFromDictionary:@{@"ownerId":@"OwnerId"}];
    [mapping addAttributesFromDictionary:@{@"type":@"Type"}];
    [mapping addAttributesFromDictionary:@{@"fullpath":@"FullPath"}];
    [mapping addAttributesFromDictionary:@{@"name": @"Name"}];
    [mapping addAttributesFromDictionary:@{@"size":@"Size"}];
    [mapping addAttributesFromDictionary:@{@"linkType":@"LinkType"}];
    [mapping addAttributesFromDictionary:@{@"linkUrl":@"LinkUrl"}];
    [mapping addAttributesFromDictionary:@{@"contentType": @"ContentType"}];
    [mapping addAttributesFromDictionary:@{@"iFramed": @"Iframed"}];
    [mapping addAttributesFromDictionary:@{@"thumb":@"Thumb"}];
    [mapping addAttributesFromDictionary:@{@"thumbnailLink":@"ThumbnailLink"}];
    [mapping addAttributesFromDictionary:@{@"oembedHtml":@"OembedHtml"}];
    [mapping addAttributesFromDictionary:@{@"folderHash":@"Hash"}];
    [mapping addAttributesFromDictionary:@{@"isShared": @"IsShared"}];
    [mapping addAttributesFromDictionary:@{@"owner":@"Owner"}];
    [mapping addAttributesFromDictionary:@{@"content":@"Content"}];
    [mapping addAttributesFromDictionary:@{@"isExternal":@"IsExternal"}];
    
    
    return mapping;

}

+ (FEMMapping*)defaultMapping
{
    FEMMapping * mapping = [[FEMMapping alloc] initWithEntityName:@"Folder"];
    mapping.primaryKey = @"name";
    
    [mapping addAttributesFromDictionary:@{@"identifier":@"Id"}];
    [mapping addAttributesFromDictionary:@{@"ownerId":@"OwnerId"}];
    [mapping addAttributesFromDictionary:@{@"type":@"Type"}];
    [mapping addAttributesFromDictionary:@{@"fullpath":@"FullPath"}];
    [mapping addAttributesFromDictionary:@{@"name": @"Name"}];
    [mapping addAttributesFromDictionary:@{@"size":@"Size"}];
    [mapping addAttributesFromDictionary:@{@"isFolder":@"IsFolder"}];
    [mapping addAttributesFromDictionary:@{@"isLink": @"IsLink"}];
//    [mapping addAttributesFromDictionary:@{@"linkType":@"LinkType"}];
    FEMAttribute *linkType = [[FEMAttribute alloc]initWithProperty:@"linkType" keyPath:@"LinkType" map:^id _Nullable(id  _Nonnull value) {
        if ([value isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)value stringValue];
        }
        return value;
    } reverseMap:NULL];
    [mapping addAttribute:linkType];
    [mapping addAttributesFromDictionary:@{@"linkUrl":@"LinkUrl"}];
    [mapping addAttributesFromDictionary:@{@"contentType": @"ContentType"}];
    [mapping addAttributesFromDictionary:@{@"iFramed": @"Iframed"}];
    [mapping addAttributesFromDictionary:@{@"thumb":@"Thumb"}];
    [mapping addAttributesFromDictionary:@{@"thumbnailLink":@"ThumbnailLink"}];
    [mapping addAttributesFromDictionary:@{@"oembedHtml":@"OembedHtml"}];
    [mapping addAttributesFromDictionary:@{@"folderHash":@"Hash"}];
    [mapping addAttributesFromDictionary:@{@"isShared": @"IsShared"}];
    [mapping addAttributesFromDictionary:@{@"owner":@"Owner"}];
    [mapping addAttributesFromDictionary:@{@"content":@"Content"}];
    [mapping addAttributesFromDictionary:@{@"isExternal":@"IsExternal"}];

    
    return mapping;
}

+ (FEMMapping*)P8DefaultMapping
{
    FEMMapping * mapping = [[FEMMapping alloc] initWithEntityName:@"Folder"];
    mapping.primaryKey = @"name";
    
    [mapping addAttributesFromDictionary:@{@"identifier":@"Id"}];
    [mapping addAttributesFromDictionary:@{@"type":@"Type"}];
    [mapping addAttributesFromDictionary:@{@"fullpath":@"FullPath"}];
    [mapping addAttributesFromDictionary:@{@"name": @"Name"}];
    [mapping addAttributesFromDictionary:@{@"size":@"Size"}];
    [mapping addAttributesFromDictionary:@{@"isFolder":@"IsFolder"}];
    [mapping addAttributesFromDictionary:@{@"isLink": @"IsLink"}];
    
    
    
    FEMAttribute *linkType = [[FEMAttribute alloc]initWithProperty:@"linkType" keyPath:@"LinkType" map:^id _Nullable(id  _Nonnull value) {
        if ([value isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)value stringValue];
        }
        return value;
    } reverseMap:NULL];
    [mapping addAttribute:linkType];
    [mapping addAttributesFromDictionary:@{@"linkUrl":@"LinkUrl"}];
    [mapping addAttributesFromDictionary:@{@"iFramed": @"Iframed"}];
    [mapping addAttributesFromDictionary:@{@"thumb":@"Thumb"}];
    [mapping addAttributesFromDictionary:@{@"thumbnailLink":@"ThumbnailLink"}];
    [mapping addAttributesFromDictionary:@{@"oembedHtml":@"OembedHtml"}];
    [mapping addAttributesFromDictionary:@{@"isShared": @"Shared"}];
    [mapping addAttributesFromDictionary:@{@"owner":@"Owner"}];
    [mapping addAttributesFromDictionary:@{@"content":@"Content"}];
    [mapping addAttributesFromDictionary:@{@"isExternal":@"IsExternal"}];
    [mapping addAttributesFromDictionary:@{@"contentType": @"ContentType"}];
    
    
    [mapping addAttributesFromDictionary:@{@"ownerId":@"OwnerId"}];

    

    [mapping addAttributesFromDictionary:@{@"folderHash":@"Hash"}];


    
    


//    "Path": "",
//    "LastModified": 0,



    
    return mapping;
}

+ (FEMMapping*)P8RenameMapping
{
    FEMMapping * mapping = [[FEMMapping alloc] initWithEntityName:@"Folder"];
    mapping.primaryKey = @"name";
    
    [mapping addAttributesFromDictionary:@{@"identifier":@"Id"}];
    [mapping addAttributesFromDictionary:@{@"ownerId":@"OwnerId"}];
    [mapping addAttributesFromDictionary:@{@"type":@"Type"}];
    [mapping addAttributesFromDictionary:@{@"fullpath":@"FullPath"}];
    [mapping addAttributesFromDictionary:@{@"name": @"Name"}];
    [mapping addAttributesFromDictionary:@{@"size":@"Size"}];
    [mapping addAttributesFromDictionary:@{@"linkType":@"LinkType"}];
    [mapping addAttributesFromDictionary:@{@"linkUrl":@"LinkUrl"}];
    [mapping addAttributesFromDictionary:@{@"contentType": @"ContentType"}];
    [mapping addAttributesFromDictionary:@{@"iFramed": @"Iframed"}];
    [mapping addAttributesFromDictionary:@{@"thumb":@"Thumb"}];
    [mapping addAttributesFromDictionary:@{@"thumbnailLink":@"ThumbnailLink"}];
    [mapping addAttributesFromDictionary:@{@"oembedHtml":@"OembedHtml"}];
    [mapping addAttributesFromDictionary:@{@"folderHash":@"Hash"}];
    [mapping addAttributesFromDictionary:@{@"isShared": @"IsShared"}];
    [mapping addAttributesFromDictionary:@{@"owner":@"Owner"}];
    [mapping addAttributesFromDictionary:@{@"content":@"Content"}];
    [mapping addAttributesFromDictionary:@{@"isExternal":@"IsExternal"}];
    
    
    return mapping;
    
}
// Insert code here to add functionality to your managed object subclass

- (NSString*)embedThumbnailLink
{
    if ([self isImageContentType])
    {
        if ([self.linkUrl length])
        {
            return self.linkUrl;
        }
        
        NSString * viewLink = [NSString stringWithFormat:@"https://%@/?/Raw/FilesThumbnail/%@/%@/0/hash/%@",[Settings domain],[Settings currentAccount],self.folderHash,[Settings authToken]];
        
        return viewLink;
    }
    
    return nil;
}

- (NSString*)viewLink
{
    NSString * viewLink = [NSString stringWithFormat:@"https://%@/?/Raw/FilesView/%@/%@/0/hash/%@",[Settings domain],[Settings currentAccount],[self folderHash],[Settings authToken]];
    
    return viewLink;
}

- (NSString*)downloadLink
{    
    NSString * downloadLink =[NSString stringWithFormat:@"https://%@/?/Raw/FilesDownload/%@/%@/0/hash/%@",[Settings domain],[Settings currentAccount],[self folderHash],[Settings authToken]];
    return downloadLink;
}

- (NSURL*)downloadURL
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"downloads"];
    NSError * error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    if (error)
    {
        NSLog(@"%@",error);
    }
    return [NSURL URLWithString:filePath];
}

- (NSString*)urlScheme
{
    
    NSURL * url = [NSURL URLWithString:self.linkUrl];
    if ([[url host] isEqualToString:@"docs.google.com"])
    {
        return @"googledrive";
    }
    
    return nil;
}

- (BOOL)canEdit
{
    return YES;
//    NSLog(@"%@ %@ %@",self.owner,[Settings login],self.name);
//    return [self.owner isEqualToString:[Settings login]];
}

+ (NSArray*)imageContentTypes
{
    return  @[@"image/jpeg",@"image/pjpeg",@"image/png",@"image/tiff"];
}

- (NSString*)validContentType
{
    NSLog(@"%@",[self.name pathExtension]);
    if ([[self.name pathExtension] isEqualToString:@"pptx"] || [[self.name pathExtension] isEqualToString:@"ppt"])
    {
        return @"application/vnd.ms-powerpoint";
    }
    return [self contentType];
}

- (BOOL)isImageContentType
{
    NSArray * mimeTypes = [Folder imageContentTypes];
    if ([mimeTypes containsObject:self.contentType]) {
        return YES;
    }
    
    return NO;
}


@end

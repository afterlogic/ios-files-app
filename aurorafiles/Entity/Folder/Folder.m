//
//  Folder.m
//  aurorafiles
//
//  Created by Michael Akopyants on 15/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "Folder.h"
#import "Settings.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation Folder

#pragma mark - Awake

-(void)awakeFromInsert {
    self.fullpath = @"";
    self.parentPath = @"";
}

#pragma mark - Folder Mapping
+ (FEMMapping*)renameMapping
{
    FEMMapping * mapping = [[FEMMapping alloc] initWithEntityName:@"Folder"];
    mapping.primaryKey = @"prKey";
    
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

    [mapping addAttributesFromDictionary:@{@"prKey":@"primaryKey"}];
    
    return mapping;

}

+ (FEMMapping*)defaultMapping
{
    FEMMapping * mapping = [[FEMMapping alloc] initWithEntityName:@"Folder"];
    mapping.primaryKey = @"prKey";
    
    [mapping addAttributesFromDictionary:@{@"identifier":@"Id"}];
//    [mapping addAttributesFromDictionary:@{@"ownerId":@"OwnerId"}];
    [mapping addAttributesFromDictionary:@{@"type":@"Type"}];
    [mapping addAttributesFromDictionary:@{@"fullpath":@"FullPath"}];
    [mapping addAttributesFromDictionary:@{@"name": @"Name"}];
    [mapping addAttributesFromDictionary:@{@"size":@"Size"}];
    [mapping addAttributesFromDictionary:@{@"isFolder":@"IsFolder"}];
    [mapping addAttributesFromDictionary:@{@"isLink": @"IsLink"}];
    FEMAttribute *linkType = [[FEMAttribute alloc]initWithProperty:@"linkType" keyPath:@"LinkType" map:^id _Nullable(id  _Nonnull value) {
        if ([value isKindOfClass:[NSString class]]) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            NSNumber *myNumber = [f numberFromString:(NSString *)value];
            return myNumber;
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

    [mapping addAttributesFromDictionary:@{@"prKey":@"primaryKey"}];
    return mapping;
}

+ (FEMMapping*)P8DefaultMapping
{
    FEMMapping * mapping = [[FEMMapping alloc] initWithEntityName:@"Folder"];
    mapping.primaryKey = @"prKey";
    
    [mapping addAttributesFromDictionary:@{@"identifier":@"Id"}];
    [mapping addAttributesFromDictionary:@{@"type":@"Type"}];
    [mapping addAttributesFromDictionary:@{@"fullpath":@"FullPath"}];
    [mapping addAttributesFromDictionary:@{@"name": @"Name"}];
    [mapping addAttributesFromDictionary:@{@"size":@"Size"}];
    [mapping addAttributesFromDictionary:@{@"isFolder":@"IsFolder"}];
    [mapping addAttributesFromDictionary:@{@"isLink": @"IsLink"}];
    FEMAttribute *linkType = [[FEMAttribute alloc]initWithProperty:@"linkType" keyPath:@"LinkType" map:^id _Nullable(id  _Nonnull value) {
        if ([value isKindOfClass:[NSString class]]) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            NSNumber *myNumber = [f numberFromString:(NSString *)value];
            return myNumber;
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
    [mapping addAttributesFromDictionary:@{@"mainAction":@"MainAction"}];

    [mapping addAttributesFromDictionary:@{@"prKey":@"primaryKey"}];

    [mapping addAttributesFromDictionary:@{@"folderHash":@"Hash"}];

    
    return mapping;
}

+ (FEMMapping*)P8RenameMapping
{
    FEMMapping * mapping = [[FEMMapping alloc] initWithEntityName:@"Folder"];
    mapping.primaryKey = @"prKey";
    
    [mapping addAttributesFromDictionary:@{@"identifier":@"Id"}];
    [mapping addAttributesFromDictionary:@{@"type":@"Type"}];
    [mapping addAttributesFromDictionary:@{@"fullpath":@"FullPath"}];
    [mapping addAttributesFromDictionary:@{@"name": @"Name"}];
    [mapping addAttributesFromDictionary:@{@"size":@"Size"}];
    [mapping addAttributesFromDictionary:@{@"isFolder":@"IsFolder"}];
    [mapping addAttributesFromDictionary:@{@"isLink": @"IsLink"}];
    FEMAttribute *linkType = [[FEMAttribute alloc]initWithProperty:@"linkType" keyPath:@"LinkType" map:^id _Nullable(id  _Nonnull value) {
        if ([value isKindOfClass:[NSString class]]) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            NSNumber *myNumber = [f numberFromString:(NSString *)value];
            return myNumber;
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
    [mapping addAttributesFromDictionary:@{@"mainAction":@"MainAction"}];


    [mapping addAttributesFromDictionary:@{@"prKey":@"primaryKey"}];
    
    
    
    [mapping addAttributesFromDictionary:@{@"folderHash":@"Hash"}];
    
    
    return mapping;
    
}
// Insert code here to add functionality to your managed object subclass
#pragma mark - Folder Properties

- (NSString*)embedThumbnailLink
{
    if ([self isImageContentType])
    {
        if ([self.linkUrl length])
        {
            return self.linkUrl;
        }
        NSURL * url = [NSURL URLWithString:[Settings domain]];
        NSString * scheme = [url scheme];
        NSString * viewLink = [NSString stringWithFormat:@"%@%@/?/Raw/FilesThumbnail/%@/%@/0/hash/%@",scheme ? @"" : @"https://",[Settings domain],[Settings currentAccount],self.folderHash,[Settings authToken]];
        
        return viewLink;
    }
    
    return nil;
}

- (NSString*)viewLink
{
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [url scheme];
    NSString * viewLink = [NSString stringWithFormat:@"%@%@/?/Raw/FilesView/%@/%@/0/hash/%@",scheme ? @"" : @"https://",[Settings domain],[Settings currentAccount],[self folderHash],[Settings authToken]];
    
    return viewLink;
}

- (NSString*)downloadLink
{
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [url scheme];
    NSString * downloadLink =[NSString stringWithFormat:@"%@%@/?/Raw/FilesDownload/%@/%@/0/hash/%@",scheme ? @"" : @"https://",[Settings domain],[Settings currentAccount],[self folderHash],[Settings authToken]];
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

-(NSDictionary *)folderMOC{
    return [FEMSerializer serializeObject:self usingMapping:self.isP8 ? [Folder P8DefaultMapping] : [Folder defaultMapping]];
}

-(BOOL)isZippedFile
{
    if ([self.fullpath containsString:@".zip$ZIP:"]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Fetch

+(NSFetchRequest *)folderFetchRequestInContext:(NSManagedObjectContext *)ctx{
    NSFetchRequest *newFetchReq = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
//    return [Folder MR_createFetchRequestInContext:ctx];
    return newFetchReq;
}

+(NSFetchRequest *)getFetchRequestInContext:(NSManagedObjectContext *)context descriptors:(NSArray *)descriptors predicate:(NSPredicate *)predicate{
    NSFetchRequest * fetchRequest = [Folder folderFetchRequestInContext:context];
    fetchRequest.sortDescriptors = descriptors;
    fetchRequest.predicate = predicate;
    return fetchRequest;
}

+(NSArray *)fetchFoldersInContext:(NSManagedObjectContext *)context descriptors:(NSArray *)descriptors predicate:(NSPredicate *)predicate{

    return [context executeFetchRequest:[Folder getFetchRequestInContext:context descriptors:descriptors predicate:predicate] error:nil];
}

#pragma mark - Folder Operations

+(Folder *)createFolderFromRepresentation:(NSDictionary *)itemRef type:(BOOL )isP8 parrentPath:(NSString *)path InContext:(NSManagedObjectContext *) context{
//    Folder *item = [Folder findObjectByItemRef:itemRef context:context];
//    if (!item) {
        NSMutableDictionary * itemRefWithPrKey = itemRef.mutableCopy;
        NSString *primaryKey = [NSString stringWithFormat:@"%@:%@",itemRef[@"Type"],itemRef[@"FullPath"]];
        [itemRefWithPrKey setObject:primaryKey forKey:@"primaryKey"];
        Folder *item = [FEMDeserializer objectFromRepresentation:itemRefWithPrKey mapping:isP8 ? [Folder P8DefaultMapping]:[Folder defaultMapping] context:context];
        item.toRemove = [NSNumber numberWithBool:NO];
        item.isP8 = [NSNumber numberWithBool:isP8];
        item.parentPath = path;
//    }
    return item;
}

+(NSString *)getExistedFile:(Folder *)folder{
    NSString *filePath = nil;
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderParentPath = [folder.parentPath stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *name = [[NSString stringWithFormat:@"%@_%@",folderParentPath,folder.name]stringByReplacingOccurrencesOfString:@".zip" withString:@"_zip"];
    NSURL *fullURL = [documentsDirectoryURL URLByAppendingPathComponent:[name stringByReplacingOccurrencesOfString:@"$ZIP:" withString:@"_ZIP_"]];
    if ([fileManager fileExistsAtPath:fullURL.path]) {
        filePath =  fullURL.path;
    }
    return filePath;
}

+ (Folder *)findObjectByItemRef:(NSDictionary *)itemRef context:(NSManagedObjectContext *)ctx{
    NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@ AND fullpath = %@ AND contentType = %@ AND type = %@ AND name = %@",itemRef[@"Id"],itemRef[@"FullPath"],itemRef[@"ContentType"],itemRef[@"Type"],itemRef[@"Name"]];
    NSMutableArray * result = [Folder fetchFoldersInContext:ctx descriptors:descriptors predicate:predicate].mutableCopy;
    return result.lastObject;
}

@end
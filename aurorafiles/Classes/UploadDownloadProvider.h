//
//  UploadDownloadProvider.h
//  aurorafiles
//
//  Created by Cheshire on 30.05.17.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//


#import "Folder.h"
#import "ApiP7.h"
#import "ApiP8.h"
#import <AssetsLibrary/ALAssetRepresentation.h>

@protocol UploadDelegate
@end

@protocol DownloadDelegate
- (void)indexPathForDownloadingItem:(NSIndexPath *)indexPath;
@end


static NSString * kFileData = @"data";
static NSString * kFileName = @"name";
static NSString * kMIMEType = @"mime";

@class StorageManager;
@interface UploadDownloadProvider : NSObject <DownloadDelegate,UploadDelegate>
    @property (nonatomic, weak) id<UploadDelegate> uploadDelegate;
    @property (nonatomic, weak) id<DownloadDelegate> downloadDelegate;

- (instancetype)initWithDefaultMOC:(NSManagedObjectContext *)defaultMOC storageManager:(StorageManager *)storageManager fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;
+ (instancetype)providerWithDefaultMOC:(NSManagedObjectContext *)defaultMOC storageManager:(StorageManager *)storageManager fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;

- (void)startDownloadTaskForFile:(Folder *)file;
- (NSDictionary *)prepareFileFromAsset:(ALAsset *)asset error:(NSError *)error;

- (void)uploadFile:(NSData *)fileData
              mimeType:(NSString *)mimeType
      toFolderPath:(NSString *)uploadPath
          withName:(NSString *)fileName
       isCorporate:(BOOL)corporate
uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock
        completion:(void (^)(BOOL result))handler;

- (NSURL*)downloadURL;


@end

//
//  UploadDownloadProvider.m
//  aurorafiles
//
//  Created by Cheshire on 30.05.17.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//

#import "Settings.h"
#import "UploadDownloadProvider.h"
#import "StorageManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIAlertView+Errors.h"


@interface UploadDownloadProvider()<NSURLSessionDownloadDelegate>{

}
@property (weak, nonatomic) NSManagedObjectContext * defaultMOC;
@property (weak, nonatomic) StorageManager *storageManager;
@property (weak, nonatomic) NSFetchedResultsController *fetchedResultsController;
@end

@implementation UploadDownloadProvider

#pragma mark - Init
- (instancetype)initWithDefaultMOC:(NSManagedObjectContext *)defaultMOC storageManager:(StorageManager *)storageManager fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    self = [super init];
    if (self) {
        self.defaultMOC = defaultMOC;
        self.storageManager = storageManager;
        self.fetchedResultsController = fetchedResultsController;
    }
    return self;
}

+ (instancetype)providerWithDefaultMOC:(NSManagedObjectContext *)defaultMOC storageManager:(StorageManager *)storageManager fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    return [[self alloc] initWithDefaultMOC:defaultMOC storageManager:storageManager fetchedResultsController:fetchedResultsController];
}

#pragma mark - Public methods
- (void)startDownloadTaskForFile:(Folder *)file {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.afterlogic.files"];
    if([[Settings version] isEqualToString:@"P8"]){
        [sessionConfiguration setHTTPAdditionalHeaders:@{@"Authorization":[NSString stringWithFormat:@"Bearer %@",[Settings authToken]]}];
    }
    NSURLSession * session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    NSURLSessionDownloadTask * downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:[file downloadLink]]];
    NSNumber *downloadIdentifier = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
    file.downloadIdentifier = downloadIdentifier;

    NSError * error;

    if ([file.managedObjectContext save:&error]){
        DDLogDebug(@"downloadTask start with link -> %@ ",[NSURL URLWithString:[file downloadLink]]);
        [downloadTask resume];
    }else{
        DDLogDebug(@"Changes in file didn't save. Error desc -> %@",error.localizedDescription);
    };
}

- (NSDictionary *)prepareFileFromAsset:(ALAsset *)asset error:(NSError *)error {
    //    DDLogDebug(@"current asset - > %@ ",asset.defaultRepresentation.url);
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    Byte *buffer = (Byte*)malloc((NSUInteger)rep.size);
    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(NSUInteger)rep.size error:nil];
    NSData *fileData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
    NSString *realFileName = asset.defaultRepresentation.filename;
//    DDLogDebug(@"current fileData - > %@ ",fileData);
    NSString* MIMEType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass
            ((__bridge CFStringRef)[rep UTI], kUTTagClassMIMEType);

    return @{kFileData:fileData,
             kFileName:realFileName,
             kMIMEType:MIMEType};

}

- (void)uploadFile:(NSData *)fileData mimeType:(NSString *)mimeType toFolderPath:(NSString *)uploadPath withName:(NSString *)fileName isCorporate:(BOOL)corporate uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock completion:(void (^)(BOOL result))handler {
    if ([[Settings version]isEqualToString:@"P8"]) {
        [[ApiP8 filesModule] uploadFile:fileData
                                   mime:mimeType
                           toFolderPath:uploadPath
                               withName:fileName
                            isCorporate:corporate
                    uploadProgressBlock:uploadProgressBlock
                             completion:^(BOOL result, NSError *error) {
                                 if(error){
                                    [UIAlertView generatePopupWithError:error];
                                     handler(NO);
                                 }else{
                                     handler(result);
                                 }
                             }];
    }else{
        NSString * path = corporate ? @"corporate" : @"personal";
        if (uploadPath)
        {
            path = [NSString stringWithFormat:@"%@%@",path,uploadPath];
        }
        [[ApiP7 sharedInstance] putFile:fileData
                           toFolderPath:path
                               withName:fileName
                    uploadProgressBlock:uploadProgressBlock
                             completion:^(NSDictionary *data, NSError *error) {
                                 if(error){
                                     [UIAlertView generatePopupWithError:error];
                                     handler(NO);
                                 }else{
                                     handler(YES);
                                 }
                             }];

    }
}


#pragma mark - NSURLSessionDownloadDelegate methods
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
        NSFetchRequest * fetchDownloadRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchDownloadRequest.predicate = [NSPredicate predicateWithFormat:@"downloadIdentifier = %@ AND isDownloaded = NO",[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]];
        fetchDownloadRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"downloadIdentifier" ascending:YES]];
        fetchDownloadRequest.fetchLimit = 1;
        NSError * error;
        Folder * file = [[self.defaultMOC executeFetchRequest:fetchDownloadRequest error:&error] firstObject];
        if (file)
        {
            NSIndexPath * indxPath = [self.fetchedResultsController indexPathForObject:file];
            if (indxPath)
            {
                [self.downloadDelegate indexPathForDownloadingItem:indxPath];
            }
        }
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    if (downloadTask.error){
        DDLogError(@"download error -> %@",downloadTask.error);
    }
    NSError * error;
    DDLogDebug(@"downloadTask did finish downloading to url -> %@",location);
    NSFetchRequest * fetchDownloadRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
    NSNumber * taskIdentifier = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
    fetchDownloadRequest.predicate = [NSPredicate predicateWithFormat:@"downloadIdentifier = %@ AND isDownloaded = NO", taskIdentifier];
    fetchDownloadRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"downloadIdentifier" ascending:YES]];
    fetchDownloadRequest.fetchLimit = 1;
    NSArray * fetchedFiles = [[[[StorageManager sharedManager] DBProvider] defaultMOC] executeFetchRequest:fetchDownloadRequest error:&error];
    if (fetchedFiles.count > 0){
        Folder *file = [fetchedFiles lastObject];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *destinationFilename = file.name;
        NSString *destinationURL = [[self downloadURL].absoluteString stringByAppendingPathComponent:destinationFilename];
        NSURL *tmpUrl = [[self downloadURL] URLByAppendingPathComponent:destinationFilename];
        DDLogDebug(@"default download folder -> %@",[self downloadURL]);
        DDLogDebug(@"download file destination URL -> %@",tmpUrl);

        if ([fileManager fileExistsAtPath:destinationURL])
        {
            [fileManager removeItemAtPath:destinationURL error:nil];
        }

        BOOL success = [fileManager copyItemAtPath:location.path
                                            toPath:destinationURL
                                             error:&error];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^(){

            if (!success)
            {
                DDLogDebug(@"failed to download %@", [error userInfo]);
            }

            file.downloadIdentifier = [NSNumber numberWithInt:-1];
            file.isDownloaded = [NSNumber numberWithBool:success];
            if(success)
            {
                file.downloadedName = destinationFilename;
            }
            NSError * error;
            [file.managedObjectContext save:&error];
        }];
    }
}

#pragma mark - Utility Methods
- (NSURL*)downloadURL {
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
        DDLogError(@"%@",error);


    }
    return [NSURL URLWithString:filePath];
}

@end

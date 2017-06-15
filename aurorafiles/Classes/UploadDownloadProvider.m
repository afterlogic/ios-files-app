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
#import <AFNetworking/AFNetworking.h>


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

- (void)uploadFile:(NSData *)fileData mimeType:(NSString *)mimeType toFolderPath:(NSString *)uploadPath withName:(NSString *)fileName isCorporate:(BOOL)corporate uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock completion:(void (^)(BOOL result, NSError *error))handler {
    if ([[Settings version]isEqualToString:@"P8"]) {
        [[ApiP8 filesModule] uploadFile:fileData
                                   mime:mimeType
                           toFolderPath:uploadPath
                               withName:fileName
                            isCorporate:corporate
                    uploadProgressBlock:uploadProgressBlock
                             completion:^(BOOL result, NSError *error) {
                                 if(error){
                                    [[ErrorProvider instance] generatePopWithError:error controller:nil];
                                     handler(NO,error);
                                     return;
                                 }else{
                                     handler(result,nil);
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
                                     [[ErrorProvider instance] generatePopWithError:error controller:nil];
                                     handler(NO,error);
                                     nil;
                                 }else{
                                     handler(YES,nil);
                                 }
                             }];

    }
}

- (void)prepareForShortcutUpload:(NSString *)pageLink success:(void (^)(NSDictionary *shortcutData))successHandler failure:(void(^)(NSError *error))failureHandler{
    NSURL *url = [[NSURL alloc] initWithString:pageLink];
    NSString *fullUrl = pageLink;
    if (![url scheme]) {
        fullUrl = [NSString stringWithFormat:@"http://%@",pageLink];
    }

    AFHTTPSessionManager *manager = [AFHTTPSessionManager new];
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];

    [manager GET:fullUrl
      parameters:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
             NSData *data = [NSData new];
             if ([responseObject isKindOfClass:[NSData class]]){
                 data = responseObject;
             }

             NSString *htmlString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             NSString *findedTitle = [self scanString:htmlString startTag:@"<title>" endTag:@"</title>"];
             NSString *tmpShortcutName = findedTitle.length > 0 ? findedTitle : pageLink;
             NSString *shortcutName = tmpShortcutName;
             if(![tmpShortcutName isEqualToString:pageLink]){
                 NSArray *nameParts = [tmpShortcutName componentsSeparatedByString:@"&"];
                 shortcutName =  [[nameParts componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet].invertedSet];
             }
             NSURL *resourceUrl = task.originalRequest.URL;
             NSString *stringToWrite = [@[@"[InternetShortcut]",[NSString stringWithFormat:@"URL=%@", resourceUrl]] componentsJoinedByString:@"\n"];
             NSString *shortcutFileName = [NSString stringWithFormat:@"%@.%@",shortcutName,@"url"];
             NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:shortcutFileName];
             NSError * error = [NSError new];
             [stringToWrite writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
             NSURL *resultPath = [NSURL fileURLWithPath:filePath];
             NSString *MIMEType = [self mimeTypeForFileAtPath:resultPath.absoluteString];
             NSData * fileData = [[NSData alloc] initWithContentsOfURL:resultPath];

             NSDictionary *shortcutData = @{
                     kFileData:fileData,
                     kMIMEType:MIMEType,
                     kFileName:shortcutFileName,
                     kResultPath:resultPath.absoluteString
             };
             successHandler(shortcutData);

         } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                DDLogDebug(@"%@",error);
                [[ErrorProvider instance] generatePopWithError:error controller:nil];
                failureHandler(error);
            }];

}

#pragma mark - NSURLSessionDownloadDelegate methods
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
        if (downloadTask.error){
            DDLogError(@"download error -> %@",downloadTask.error);
            [[ErrorProvider instance] generatePopWithError:downloadTask.error controller:nil];
            [downloadTask cancel];
            return;
        }
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
        [[ErrorProvider instance] generatePopWithError:downloadTask.error controller:nil];
        [downloadTask cancel];
        return;
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
                [[ErrorProvider instance] generatePopWithError:downloadTask.error controller:nil];
                return;
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

- (NSString *)scanString:(NSString *)string
                startTag:(NSString *)startTag
                  endTag:(NSString *)endTag
{

    NSString* scanString = @"";

    if (string.length > 0) {

        NSScanner* scanner = [[NSScanner alloc] initWithString:string];

        @try {
            [scanner scanUpToString:startTag intoString:nil];
            scanner.scanLocation += [startTag length];
            [scanner scanUpToString:endTag intoString:&scanString];
        }
        @catch (NSException *exception) {
            return nil;
        }
        @finally {
            return scanString;
        }

    }

    return scanString;

}

- (NSString*)mimeTypeForFileAtPath: (NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return @"application/octet-stream";
    }
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return ( __bridge NSString *)mimeType;
}

@end

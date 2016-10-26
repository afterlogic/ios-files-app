//
//  files.m
//  aurorafiles
//
//  Created by Cheshire on 19.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "files.h"
#import "Folder.h"
#import "AFNetworking.h"
#import "Settings.h"
#import "NSURLRequest+requestGenerator.h"
#import "StorageManager.h"

@interface files(){
    AFHTTPRequestOperationManager *manager;
    NSMutableDictionary* operationsQueue;
}

@end

@implementation files
static NSString *moduleName = @"Files";
static NSString *methodGetFiles = @"GetFiles"; //√
static NSString *methodDelete = @"Delete"; //когда-нибудь
static NSString *methodCreateFolder = @"CreateFolder"; //√
static NSString *methodRename = @"Rename"; //√
static NSString *methodQuota = @"GetQuota"; //√
static NSString *methodGetFileThumbail = @"GetFileThumbnail"; //√
static NSString *methodGetFileInfo = @"GetFileInfo"; //√
static NSString *methodGetFileView = @"ViewFile"; //√
static NSString *methodUploadFile = @"UploadFile"; //√

-(id)init{
    self = [super init ];
    if(self){
        manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [manager.requestSerializer setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
        
        operationsQueue = [NSMutableDictionary new];
    }
    return self;
}

+ (instancetype) sharedInstance
{
    static files *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[files alloc] init];
    });
    return sharedInstance;
}

-(NSString *)moduleName{
    return moduleName;
}

///
- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type completion:(void (^)(NSArray *items))handler{
    [self getFilesForFolder:folderName withType:type searchPattern:@"" completion:handler];
}

- (void)searchFilesInFolder:(NSString *)folderName withType:(NSString *)type fileName:(NSString *)fileName completion:(void (^)(NSArray *items))handler{
    [self getFilesForFolder:folderName withType:type searchPattern:fileName completion:handler];
}

- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type searchPattern:(NSString *)pattern completion:(void (^)(NSArray *items))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetFiles,
                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":folderName,
                                                                                    @"Pattern":pattern}}];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }
            if (error)
            {
                NSLog(@"%@",[error localizedDescription]);
                handler(nil);
                return ;
            }
            NSArray * items;
            if (json && [json isKindOfClass:[NSDictionary class]] && [[json objectForKey:@"Result"] isKindOfClass:[NSArray class]])
            {
                for (NSDictionary* module in [json objectForKey:@"Result"]) {
                    if ([[module valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[module valueForKey:@"Module"] isEqualToString:moduleName] && [[module valueForKey:@"Method"] isEqualToString:methodGetFiles]) {
                        items = [[[module objectForKey:@"Result"] objectForKey:@"Items"] isKindOfClass:[NSArray class]] ? [[module objectForKey:@"Result"] objectForKey:@"Items"] : @[];
                    }
                }
            }
            else
            {
                items = @[];
            }
            handler(items);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(nil);
        });
    }];
    
    [manager.operationQueue addOperation:operation];
}

///
- (void)getUserFilestorageQoutaWithCompletion:(void(^)(NSString *publicID, NSError *error))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodQuota,
                                                                    @"AuthToken":[Settings authToken]}];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSString *userInfoResult = @"";
            if (![json isKindOfClass:[NSArray class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }else{
                if ([json count] < 2) {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                }
                NSDictionary *userData = [json firstObject];
                userInfoResult = [userData valueForKeyPath:@"Result.PublicId"];
            }
            if (error)
            {
                NSLog(@"%@",[error localizedDescription]);
                handler(nil,error);
                return ;
            }
            
            handler(userInfoResult,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(nil,error);
        });
    }];
    
    [manager.operationQueue addOperation:operation];

}
///

- (void)deleteFile:(Folder *)file isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess))handler{
    [self deleteFiles:@[file] isCorporate:corporate completion:handler];
}

- (void)deleteFiles:(NSArray<Folder *>*)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodDelete,
                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":corporate ? @"corporate" : @"personal",
                                                                                    @"Items":files}}];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            BOOL result = NO;
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    if ([[json valueForKey:@"Result"]count] >=2) {
                        if (json && [json isKindOfClass:[NSDictionary class]] && [[json objectForKey:@"Result"] isKindOfClass:[NSArray class]])
                        {
                            NSArray *modules = [json objectForKey:@"Result"];
                            for (NSDictionary* module in modules) {
                                if ([[module valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[module valueForKey:@"Module"] isEqualToString:moduleName] && [[module valueForKey:@"Method"] isEqualToString:methodDelete]) {
                                    result = [module valueForKey:@"Result"];
                                }
                            }
                        }
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];
                    handler(nil);
                    return;
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];
                handler(nil);
                return;
            }
            handler(result);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(nil);
        });
    }];
    
    [manager.operationQueue addOperation:operation];

}


- (void)getThumbnailsForFiles:(NSArray <Folder *>*)files withCompletion:(void(^)(bool success))handler{
    NSMutableArray <Folder *>* items = files.mutableCopy;
    if (items.count == 0) {
        handler(YES);
        return;
    }
    Folder *currentItem = [items lastObject];
    
    [[StorageManager sharedManager]updateFileThumbnail:currentItem type:currentItem.type context:nil complition:^(UIImage *thumbnail) {
        if (thumbnail) {
            [items removeObject:currentItem];
        }
        [self getThumbnailsForFiles:items withCompletion:^(bool success) {
            handler(success);
        }];
    }];
}

- (void)getFileThumbnail:(NSString *)folderName type:(NSString *)type path:(NSString *)path withCompletion:(void(^)(NSString *thumbnail))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetFileThumbail,
                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":path,
                                                                                    @"Name":folderName}}];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            NSString *thumbnail = nil;
            NSString *path = nil;
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    if ([[json valueForKey:@"Result"]count] >=2) {
                        if (json && [json isKindOfClass:[NSDictionary class]] && [[json objectForKey:@"Result"] isKindOfClass:[NSArray class]])
                        {
                            for (NSDictionary* module in [json objectForKey:@"Result"]) {
                                if ([[module valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[module valueForKey:@"Module"] isEqualToString:moduleName] && [[module valueForKey:@"Method"] isEqualToString:methodGetFileThumbail] && [[module valueForKey:@"Result"] isKindOfClass:[NSString class]]) {
                                    thumbnail = [module valueForKey:@"Result"];
                                    NSData *data = [[NSData alloc]initWithBase64EncodedString:thumbnail options:0];
                                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"thumb_%@",folderName]];
                                    [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
                                }
                            }
                        }
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];
            }
            if (!path.length) {
                handler(nil);
                return;
            }
            handler(path);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(nil);
        });
    }];
    
    [manager.operationQueue addOperation:operation];
    [operationsQueue setObject:operation forKey:folderName];

}

- (void)stopFileThumb:(NSString *)folderName{
    AFHTTPRequestOperation *operation = [operationsQueue objectForKey:folderName];
    [operation cancel];
}
///

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodRename,
                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":path,
                                                                                    @"Name":name,
                                                                                    @"NewName":newName,
                                                                                    @"IsLink":isLink ? @"true" : @"false"}}];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            BOOL result = NO;
//            NSString *thumbnail = @"";
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    if ([[json valueForKey:@"Result"]count] >=2) {
                        if (json && [json isKindOfClass:[NSDictionary class]] && [[json objectForKey:@"Result"] isKindOfClass:[NSArray class]])
                        {
                            for (NSDictionary* module in [json objectForKey:@"Result"]) {
                                if ([[module valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[module valueForKey:@"Module"] isEqualToString:moduleName] && [[module valueForKey:@"Method"] isEqualToString:methodRename]) {
                                    //                                    thumbnail = [[NSData alloc]initWithBase64EncodedString:[module valueForKey:@"Result"] options:0];
                                    result = [module valueForKey:@"Result"];
                                }
                            }
                        }
                    }
                }
                
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];
            }
            handler(result);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(NO);
        });
    }];
    
    [manager.operationQueue addOperation:operation];

}
///
- (void)getFileInfoForName:(NSString *)name path:(NSString *)path corporate:(BOOL)corporate completion:(void (^)(NSDictionary *result))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetFileInfo,
                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":corporate ? @"corporate" : @"personal",
                                                                                    @"Path":path,
                                                                                    @"Name":name,
                                                                                    @"UserID":[Settings currentAccount]}}];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            NSDictionary *result = [NSDictionary new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    if ([[json valueForKey:@"Result"]count] >=2) {
                        if (json && [json isKindOfClass:[NSDictionary class]] && [[json objectForKey:@"Result"] isKindOfClass:[NSArray class]])
                        {
                            for (NSDictionary* module in [json objectForKey:@"Result"]) {
                                if ([[module valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[module valueForKey:@"Module"] isEqualToString:moduleName] && [[module valueForKey:@"Method"] isEqualToString:methodGetFileInfo]) {
                                    result = [module valueForKey:@"Result"];
                                }
                            }
                        }
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];
                    handler(nil);
                    return;
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];
                handler(nil);
                return;
            }
            handler(result);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(nil);
        });
    }];
    
    [manager.operationQueue addOperation:operation];
    

}
///
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL result))handler{
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodCreateFolder,
                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":corporate ? @"corporate" : @"personal",
                                                                                    @"Path":path.length ? path : @"",
                                                                                    @"FolderName":name}}];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            BOOL result = NO;
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    if ([[json valueForKey:@"Result"]count] >=2) {
                        if (json && [json isKindOfClass:[NSDictionary class]] && [[json objectForKey:@"Result"] isKindOfClass:[NSArray class]])
                        {
                            for (NSDictionary* module in [json objectForKey:@"Result"]) {
                                if ([[module valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[module valueForKey:@"Module"] isEqualToString:moduleName] && [[module valueForKey:@"Method"] isEqualToString:methodCreateFolder]) {
                                    result = [module valueForKey:@"Result"];
                                }
                            }
                        }
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];
                    handler(nil);
                    return;
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];
                handler(nil);
                return;
            }
            handler(result);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(nil);
        });
    }];
    
    [manager.operationQueue addOperation:operation];
}
///
- (void)uploadFile:(NSData *)file mime:(NSString *)mime toFolderPath:(NSString *)path withName:(NSString *)name isCorporate:(BOOL)corporate uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock completion:(void (^)(NSDictionary *response))handler
{
    
    NSString *storageType = [NSString stringWithString:corporate ? @"corporate" : @"personal"];
    NSString *pathTmp = [NSString stringWithFormat:@"%@",path.length ? [NSString stringWithFormat:@"/%@",path] : @""];
    NSString *Link = [NSString stringWithFormat:@"http://cloudtest.afterlogic.com/?/upload/files/%@/%@/%@",storageType,pathTmp,name];
    NSURL *testUrl = [[NSURL alloc]initWithString:[Link stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSDictionary *headers = @{ @"auth-token": [Settings authToken],
                               @"cache-control": @"no-cache"};
    
    NSData *postData = file;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:testUrl
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithData:postData]];
    
    
 
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error = nil;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            
            id json = nil;
            if (data)
            {
                json =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            }
            
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }
            if (error)
            {
                NSLog(@"%@",[error localizedDescription]);
                handler(nil);
                return ;
            }
            handler(json);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (error)
            {
                NSLog(@"%@",[error localizedDescription]);
                handler(nil);
                return ;
            }
        });
    }];
    
    [operation setUploadProgressBlock:^(NSUInteger __unused bytesWritten,
                                        long long totalBytesWritten,
                                        long long totalBytesExpectedToWrite) {
        float progress = (float)totalBytesWritten / (float)file.length;
        uploadProgressBlock(progress);
    }];
    
    [manager.operationQueue addOperation:operation];

}

///
- (void)getFileView:(Folder *)folder type:(NSString *)type path:(NSString *)path withProgress:(void (^)(float progress))progressBlock withCompletion:(void(^)(NSString *thumbnail))handler{
    NSURLRequest *request = [NSURLRequest p8DownloadRequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetFileView,
                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Format":@"Raw",
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":path,
                                                                                    @"Name":folder.name}}];
    
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *downloadManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    
    [downloadManager setDownloadTaskDidWriteDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite){
        float written = totalBytesWritten;
        float percentageCompleted = written/[folder.size floatValue];
        progressBlock(percentageCompleted);
    }];
    
    //Start the download
    NSURLSessionDownloadTask *downloadTask = [downloadManager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        //Getting the path of the document directory
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *fullURL = [documentsDirectoryURL URLByAppendingPathComponent:folder.name];
        //If we already have a video file saved, remove it from the phone
        [self removeFileAtPath:fullURL];
        return fullURL;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error) {
            handler(filePath.path);
        } else {
            handler(@"");
        }
    }];
    [downloadTask resume];
}

- (void)removeFileAtPath:(NSURL *)filePath
{
    NSString *stringPath = filePath.path;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:stringPath]) {
        [fileManager removeItemAtPath:stringPath error:NULL];
    }
}
@end

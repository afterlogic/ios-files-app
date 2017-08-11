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
#import "NSString+URLEncode.h"

#import <AFNetworking+AutoRetry/AFHTTPRequestOperationManager+AutoRetry.h>

static int retryCount = 0;
static const int retryInterval = 5;

@interface files(){
    AFHTTPRequestOperationManager *manager;
    NSMutableDictionary* operationsQueue;
    NSMutableArray <NSMutableDictionary *>* resultedFiles;
    NSMutableArray <NSMutableDictionary *>* itemsForThumb;
}

@end

@implementation files
static NSString *moduleName = @"Files";
static NSString *methodGetFiles = @"GetFiles"; //√
static NSString *methodDelete = @"Delete"; //√
static NSString *methodCreateFolder = @"CreateFolder"; //√
static NSString *methodRename = @"Rename"; //√
static NSString *methodQuota = @"GetQuota"; //√
static NSString *methodGetFileThumbail = @"GetFileThumbnail"; //√
static NSString *methodGetFileInfo = @"GetFileInfo"; //√
static NSString *methodGetFileView = @"ViewFile"; //√
static NSString *methodUploadFile = @"UploadFile"; //√
static NSString *methodGetPublicLink = @"CreatePublicLink";

-(id)init{
    self = [super init ];
    if(self){
        manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [manager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        resultedFiles = [NSMutableArray new];
        operationsQueue = [NSMutableDictionary new];
        
//        retryCount = 3;
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
- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type completion:(void (^)(NSArray *items, NSError * error))handler{
    [self getFilesForFolder:folderName withType:type searchPattern:@"" completion:handler];
}


- (void)searchFilesInSection:(NSString *)type pattern:(NSString *)searchPattern completion:(void (^)(NSArray *, NSError *))handler{
    [self getFilesForFolder:@"" withType:type searchPattern:searchPattern completion:handler];
}
- (void)searchFilesInFolder:(NSString *)folderName withType:(NSString *)type fileName:(NSString *)fileName completion:(void (^)(NSArray *items, NSError *error))handler{
    [self getFilesForFolder:folderName withType:type searchPattern:fileName completion:handler];
}

- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type searchPattern:(NSString *)pattern completion:(void (^)(NSArray *items, NSError *error))handler{
    NSString *encodedName = [folderName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetFiles,
//                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":encodedName,
                                                                                    @"Pattern":pattern}}].mutableCopy;
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
    
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if (![json isKindOfClass:[NSDictionary class]]) {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }else if ([[json objectForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]) {
                NSNumber *errorCode = [json objectForKey:@"ErrorCode"];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);

                handler(nil,error);
                return ;
            }
            NSArray * items;
            if (json && [json isKindOfClass:[NSDictionary class]] && [[json objectForKey:@"Result"] isKindOfClass:[NSDictionary class]])
            {
                NSDictionary * module = [json objectForKey:@"Result"];
                if ([module isKindOfClass:[NSNumber class]]) {
                    items = @[];
                }else if([[module objectForKey:@"Items"] isKindOfClass:[NSDictionary class]]){
                    NSMutableArray *itemsTmp = [NSMutableArray new];
                    for (NSString *key in [module objectForKey:@"Items"]) {
                        NSDictionary *item = [[module objectForKey:@"Items"] objectForKey:key];
                        [itemsTmp addObject:item.mutableCopy];
                    }
                    items = itemsTmp.copy;
                }else{
                    NSMutableArray *itemsTmp = [NSMutableArray new];
                    if ([[module objectForKey:@"Items"] isKindOfClass:[NSArray class]]) {
                        for (NSDictionary *item in [module objectForKey:@"Items"]) {
                            [itemsTmp addObject:item.mutableCopy];
                        }
                        items = itemsTmp.copy;
                    }else{
                        items =  @[];
                    }
                }
            }
            else
            {
                items = @[];
            }
            handler(items,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            handler(nil,error);
        });
    }];
    
    [manager.operationQueue addOperation:operation];
}

//TODO: закоментирован метод для проверки доступного пользователю места на файлохранилище. Раскоментировать при необходимости
//- (void)getUserFilestorageQoutaWithCompletion:(void(^)(NSString *publicID, NSError *error))handler{
//    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
//                                                                    @"Method":methodQuota,
//                                                                    @"AuthToken":[Settings authToken]}];
//    
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
//        dispatch_async(dispatch_get_main_queue(), ^(){
//            NSError *error;
//            NSData *data = [NSData new];
//            if ([responseObject isKindOfClass:[NSData class]]) {
//                data = responseObject;
//            }
//            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//            NSString *userInfoResult = @"";
//            if (![json isKindOfClass:[NSDictionary class]])
//            {
//                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
//            }else{
//                if ([json count] < 2) {
//                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
//                }
//                NSDictionary *userData = [json objectForKey:@"Result"];
//                userInfoResult = [userData valueForKeyPath:@"Result.PublicId"];
//            }
//            if (error)
//            {
//                DDLogError(@"%@",[error localizedDescription]);
//                handler(nil,error);
//                return ;
//            }
//            
//            handler(userInfoResult,nil);
//        });
//    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
//        dispatch_async(dispatch_get_main_queue(), ^(){
//            DDLogError(@"HTTP Request failed: %@", error);
//            handler(nil,error);
//        });
//    }];
//    
//    [manager.operationQueue addOperation:operation];
//
//}
//

- (void)deleteFile:(Folder *)file isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess, NSError *error))handler{
    [self deleteFiles:@[file] isCorporate:corporate completion:handler];
}

- (void)deleteFiles:(NSArray<Folder *> *)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess, NSError *error))handler{
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodDelete,
//                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":corporate ? @"corporate" : @"personal",
                                                                                    @"Items":files}}].mutableCopy;
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
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
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSNumber class]])
                {
                    result = [json valueForKey:@"Result"];
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];

                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];

            }
            if(error){
                handler(nil,error);
                return;
            }
            handler(result,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            handler(nil,error);
        });
    } autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];

}

- (void)prepareForThumbUpdate {
    [itemsForThumb removeAllObjects];
    [resultedFiles removeAllObjects];
}
- (void)getThumbnailsForFiles:(NSArray <NSMutableDictionary *> *)files withCompletion:(void (^)(NSArray *resultedItems))handler{
    itemsForThumb = files.mutableCopy;
    if (itemsForThumb.count == 0) {
        handler(resultedFiles);
        return;
    }

    for (NSMutableDictionary *item in files) {
        NSNumber *isFolderNum = item[@"IsFolder"];
        NSNumber *isLinkNum = item[@"IsLink"];
        bool isFolder = [isFolderNum boolValue];
        bool isLink = [isLinkNum boolValue];
        if (isFolder || isLink) {
            [resultedFiles addObject:item];
            [itemsForThumb removeObject:item];
        }
        
        NSString *itemFullPath = item[@"FullPath"];
        if ([itemFullPath containsString:@"$ZIP:"]) {
            [resultedFiles addObject:item];
            [itemsForThumb removeObject:item];
        }
        
    }
    
    NSMutableDictionary *currentItem = [itemsForThumb lastObject];
    if (itemsForThumb.count == 0) {
        handler(resultedFiles);
        return;
    }else{
        currentItem = [itemsForThumb lastObject];
    }

    [self updateFileThumbnail:currentItem type:currentItem[@"Type"] complition:^(NSMutableDictionary* itemRef) {
        if (itemRef) {
            [itemsForThumb removeObject:currentItem];
            [resultedFiles addObject:itemRef];
        }
        [self getThumbnailsForFiles:itemsForThumb withCompletion:^(NSArray *items) {
            handler(items);
        }];
    }];

}

- (void)updateFileThumbnail:(NSMutableDictionary *)file type:(NSString*)type complition:(void (^)(NSMutableDictionary* itemRef))handler{
    NSString * filepathPath = file ? file[@"FullPath"] : @"";
    NSMutableArray *pathArr = [filepathPath componentsSeparatedByString:@"/"].mutableCopy;
    NSString *fileName = file[@"Name"];
    [pathArr removeObject:[pathArr lastObject]];
    NSString *parentPath = pathArr.count >1 ? [pathArr componentsJoinedByString:@"/"] : @"";

    [self getThumbnailForFileNamed:fileName type:type path:parentPath withCompletion:^(NSString *thumbnail, NSError *error) {
        if (thumbnail) {
            __block NSError *error = nil;
            __block NSData *data;
            __block UIImage *image;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([thumbnail length] && [fileManager fileExistsAtPath:thumbnail]) {
                data= [[NSData alloc]initWithContentsOfFile:thumbnail];

                file[@"ThumbnailLink"] = thumbnail;
                if (error) {
                    DDLogError(@"save error -> %@", error.localizedFailureReason);
                }
                image = [UIImage imageWithData:data];
            }else{
                handler (nil);
                return;
            }
            if (error)
            {
                DDLogError(@"%@",[error userInfo]);
                handler (nil);
                return;
            }
            handler(file);
            return ;
        }
        handler (nil);
    }];
}

- (void)getThumbnailForFileNamed:(NSString *)folderName type:(NSString *)type path:(NSString *)parentPath withCompletion:(void (^)(NSString *thumbnail, NSError *error))handler{
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetFileThumbail,
//                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":parentPath,
                                                                                    @"Name":folderName}}].mutableCopy;
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = @"GET";
    
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
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSString class]])
                {
                    if ([[json objectForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]) {
                        NSNumber *errorCode = [json objectForKey:@"ErrorCode"];
                        error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                    }else if ([[json valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[json valueForKey:@"Module"] isEqualToString:moduleName] && [[json valueForKey:@"Method"] isEqualToString:methodGetFileThumbail] && [[json valueForKey:@"Result"] isKindOfClass:[NSString class]]) {
                        thumbnail = [json valueForKey:@"Result"];
                        NSData *data = [[NSData alloc]initWithBase64EncodedString:thumbnail options:0];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        
                        NSString *folderParentPath = [parentPath stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                        NSString *name = [NSString stringWithFormat:@"thumb_%@_%@",folderParentPath,folderName];
                        
                        path = [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
                        [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
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
                handler(nil,error);
                return;
            }
            handler(path,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);

            handler(nil,error);
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

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success, NSError *error))handler{
    
    NSString *encodedName = [name urlEncodeUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedNewName = [newName urlEncodeUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedPath = path.length ? [path urlEncodeUsingEncoding:NSUTF8StringEncoding] : @"";
    
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodRename,
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":encodedPath,
                                                                                    @"Name":encodedName,
                                                                                    @"NewName":encodedNewName,
                                                                                    @"IsLink":isLink ? @"true" : @"false"}}].mutableCopy;
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
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
                if ([[json objectForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]) {
                    NSNumber *errorCode = [json objectForKey:@"ErrorCode"];
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                }else if ([[json valueForKey:@"Result"] isKindOfClass:[NSNumber class]])
                {
                    if ([[json valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[json valueForKey:@"Module"] isEqualToString:moduleName] && [[json valueForKey:@"Method"] isEqualToString:methodRename]) {
                        result = [json valueForKey:@"Result"];
                    }
                }
                
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];

                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];

            }
            handler(result,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);

            handler(NO,error);
        });
    } autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];

}
///
- (void)getFileInfoForName:(NSString *)name path:(NSString *)path corporate:(NSString *)type completion:(void (^)(NSDictionary *result, NSError *error))handler{
    NSString *encodedName = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString *encodedPath = path.length ? [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] : @"";
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetFileInfo,
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":encodedPath,
                                                                                    @"Name":encodedName,
                                                                                    @"UserID":[Settings currentAccount]}}].mutableCopy;
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
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
                if ([[json objectForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]) {
                    NSNumber *errorCode = [json objectForKey:@"ErrorCode"];
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                    handler(nil, error);
                    return;
                }else if ([[json valueForKey:@"Result"] isKindOfClass:[NSDictionary class]])
                {
                    if ([[json valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[json valueForKey:@"Module"] isEqualToString:moduleName] && [[json valueForKey:@"Method"] isEqualToString:methodGetFileInfo]) {
                        result = [json valueForKey:@"Result"];
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];

                    handler(nil,error);
                    return;
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];
                handler(nil,error);

                return;
            }
            handler(result,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);

            handler(nil,error);
        });
    } autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
}
///
- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL result, NSError *error))handler{
    
    NSString *encodedPath = path.length ? [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] : @"";
    NSString *encodedName = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodCreateFolder,
//                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Parameters":@{@"Type":corporate ? @"corporate" : @"personal",
                                                                                    @"Path":encodedPath,
                                                                                    @"FolderName":encodedName}}].mutableCopy;
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
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
                if ([[json objectForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]) {
                    NSNumber *errorCode = [json objectForKey:@"ErrorCode"];
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                    handler(nil, error);
                    return;
                }else if ([[json valueForKey:@"Result"] isKindOfClass:[NSNumber class]])
                {
                    if ([[json valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[json valueForKey:@"Module"] isEqualToString:moduleName] && [[json valueForKey:@"Method"] isEqualToString:methodCreateFolder]) {
                        result = [json valueForKey:@"Result"];
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];

                    handler(nil,error);
                    return;
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];

                handler(nil,error);
                return;
            }
            handler(result,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);

            handler(nil,error);
        });
    } autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
}
///
- (void)uploadFile:(NSData *)file mime:(NSString *)mime toFolderPath:(NSString *)path withName:(NSString *)name isCorporate:(BOOL)corporate uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock completion:(void (^)(BOOL result, NSError *error))handler
{
    
    
    NSString *storageType = [NSString stringWithString:corporate ? @"corporate" : @"personal"];
    NSString *pathTmp = [NSString stringWithFormat:@"%@",path.length ? [NSString stringWithFormat:@"/%@",path] : @""];
//    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [Settings domainScheme];
    NSString *Link = [NSString stringWithFormat:@"%@%@/?/upload/files/%@%@/%@",scheme ? scheme : @"https://",[Settings domain],storageType,[pathTmp urlEncodeUsingEncoding:NSUTF8StringEncoding],[name urlEncodeUsingEncoding:NSUTF8StringEncoding]];
    NSURL *testUrl = [[NSURL alloc]initWithString:Link];
    
    
    NSDictionary *headers = @{
//                              @"auth-token": [Settings authToken],
                               @"cache-control": @"no-cache",
                               @"Authorization": [NSString stringWithFormat:@"Bearer %@",[Settings authToken]]};
    
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
            NSString *result;
            BOOL handlResult = false;
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            if (data)
            {
                result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                handlResult = [result isEqualToString:@"true"];
                DDLogError(@"%@",result);
            }
            
            if (!handlResult)
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);

                handler(handlResult,error);
                return ;
            }
            handler(handlResult,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);

                handler(NO,error);
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
- (void)getFileView:(Folder *)folder type:(NSString *)type withProgress:(void (^)(float progress))progressBlock withCompletion:(void (^)(NSString *thumbnail))handler{
    
    NSString * filepathPath;
    float  fileSize;
    NSString *path;
    NSString *name;
    NSString *suggestedFilename;
    if (folder.isZippedFile) {
        filepathPath = folder ? folder.fullpath : @"";
        NSMutableArray *pathPrtsArr = [filepathPath componentsSeparatedByString:@"$ZIP:"].mutableCopy;
        DDLogError(@"%@",pathPrtsArr);
        path = [pathPrtsArr firstObject];
        name = [pathPrtsArr lastObject];
        fileSize = [folder.size floatValue];
        suggestedFilename = [name lastPathComponent];
    }else{
        filepathPath = folder ? folder.fullpath : @"";
        NSMutableArray *pathArr = [filepathPath componentsSeparatedByString:@"/"].mutableCopy;
        [pathArr removeObject:[pathArr lastObject]];
        path = [pathArr componentsJoinedByString:@"/"];
        name = folder.name;
        fileSize = [folder.size floatValue];
        suggestedFilename = folder.name;
    }
    
    
    NSString *existedPath = [Folder getExistedFile:folder];
    if (existedPath) {
        progressBlock(100.0f);
        handler(existedPath);
        return;
    }
    
    
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodGetFileView,
//                                                                    @"AuthToken":[Settings authToken],
                                                                    @"Format":@"Raw",
                                                                    @"Parameters":@{@"Type":type,
                                                                                    @"Path":path,
                                                                                    @"Name":name}
                                                                    }].mutableCopy;
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *downloadManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    
    [downloadManager setDownloadTaskDidWriteDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite){
        float written = totalBytesWritten;
        float percentageCompleted = written/fileSize;
        progressBlock(percentageCompleted);
    }];
    
    //Start the download
    NSURLSessionDownloadTask *downloadTask = [downloadManager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        //Getting the path of the document directory
        if (![[response suggestedFilename] isEqualToString:suggestedFilename]) {
            return nil;
        }
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *originalFileUrl = [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];

        return originalFileUrl;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error) {
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            NSString *folderParentPath = [folder.parentPath stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
            NSString *folderName = folder.name ? folder.name : @"";
            NSString *name = [[NSString stringWithFormat:@"%@_%@",folderParentPath,folderName]stringByReplacingOccurrencesOfString:@".zip" withString:@"_zip"];
            NSURL *fullURL = [documentsDirectoryURL URLByAppendingPathComponent:[name stringByReplacingOccurrencesOfString:@"$ZIP:" withString:@"_ZIP_"]];
            [self removeFileAtPath:fullURL];
            NSError *copyError = [[NSError alloc]init];
            
            if([[NSFileManager defaultManager]fileExistsAtPath:filePath.path]){
                if([[NSFileManager defaultManager]copyItemAtPath:filePath.path toPath:fullURL.path error:&copyError]){
                    handler(fullURL.path);
                }else{
                    DDLogError(@"copy item error -> %@",copyError.localizedDescription);
                    handler(@"");
                }
            }else{
                handler(@"");
            }
        } else {
            handler(@"");
        }
    }];
    [downloadTask resume];
}

- (void)getPublicLinkForFileNamed:(NSString *)name filePath:(NSString *)filePath type:(NSString *)type size:(NSString *)size isFolder:(BOOL)isFolder completion:(void (^)(NSString *publicLink, NSError *error))completion{
    NSMutableArray *filePathComponents = [filePath componentsSeparatedByString:@"/"].mutableCopy;
    DDLogError(@"components -> %@", filePathComponents);
    [filePathComponents removeLastObject];
    filePath = [filePathComponents count] == 1 ? @"" : [filePathComponents componentsJoinedByString:@"/"];
    NSMutableURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
            @"Method":methodGetPublicLink,
//            @"AuthToken":[Settings authToken],
            @"Parameters":@{
                    @"Type":type,
                    @"Path":filePath,
                    @"Name":name,
                    @"Size":size,
                    @"IsFolder":[NSNumber numberWithBool:isFolder].stringValue
            }
    }].mutableCopy;
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
//    __block NSString * linkHostName = @"localhostshare";
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            NSString *result = [NSString new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json objectForKey:@"ErrorCode"] isKindOfClass:[NSNumber class]]) {
                    NSNumber *errorCode = [json objectForKey:@"ErrorCode"];
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                    completion(nil, error);
                    return;
                }else if ([[json valueForKey:@"Result"] isKindOfClass:[NSString class]])
                {
                    if ([[json valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[json valueForKey:@"Module"] isEqualToString:moduleName] && [[json valueForKey:@"Method"] isEqualToString:methodGetPublicLink]) {
                        result = [json valueForKey:@"Result"];
                        result = [NSString stringWithFormat:@"%@/%@", [Settings domain],result];
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"server is unavailable now", @"")}];

                    completion(nil,error);
                    return;
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:9 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Aurora version smaller than 8", @"")}];

                completion(nil,error);
                return;
            }
            completion(result,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            completion(nil,error);
        });
    } autoRetryOf:retryCount retryInterval:retryInterval];

    [manager.operationQueue addOperation:operation];
}


- (void)removeFileAtPath:(NSURL *)filePath
{
    NSString *stringPath = filePath.path;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:stringPath]) {
        [fileManager removeItemAtPath:stringPath error:NULL];
    }
}

//-(NSString *)getExistedFile:(Folder *)folder{
//    NSString *filePath = nil;
//    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *folderParentPath = [folder.parentPath stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
//    NSString *name = [[NSString stringWithFormat:@"%@_%@",folderParentPath,folder.name]stringByReplacingOccurrencesOfString:@".zip" withString:@"_zip"];
//    NSURL *fullURL = [documentsDirectoryURL URLByAppendingPathComponent:[name stringByReplacingOccurrencesOfString:@"$ZIP:" withString:@"_ZIP_"]];
//    if ([fileManager fileExistsAtPath:fullURL.path]) {
//        filePath =  fullURL.path;
//    }
//    return filePath;
//}

-(NSString *)getExistedThumbnailForFile:(Folder *)folder{
    NSString *filePath = nil;
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderParentPath = [folder.parentPath stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *name = [NSString stringWithFormat:@"thumb_%@_%@",folderParentPath,folder.name];
    NSURL *fullURL = [documentsDirectoryURL URLByAppendingPathComponent:name];
    if ([fileManager fileExistsAtPath:fullURL.path]) {
        filePath =  fullURL.path;
    }
    return filePath;
}


-(void)cancelOperations{
    retryCount = 0;
    itemsForThumb = nil;
    [manager.operationQueue cancelAllOperations];
}
@end

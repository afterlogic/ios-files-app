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

@interface files(){
    AFHTTPRequestOperationManager *manager;
    NSMutableDictionary* operationsQueue;
}

@end

@implementation files
static NSString *moduleName = @"Files";
static NSString *methodGetFiles = @"GetFiles";
static NSString *methodDelete = @"Delete";
static NSString *methodCreateFolder = @"CreateFolder";
static NSString *methodRename = @"Rename";
static NSString *methodQuota = @"GetQuota";
static NSString *methodGetFileThumbail = @"GetFileThumbnail";

static NSString *methodUploadFile = @"UploadFile";

-(id)init{
    self = [super init ];
    if(self){
        manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
        
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
- (void)deleteFile:(Folder *)file isCorporate:(BOOL)corporate completion:(void (^)(NSDictionary *))handler{
    [self deleteFiles:@[file] isCorporate:corporate completion:handler];
}

- (void)deleteFiles:(NSArray<Folder *>*)files isCorporate:(BOOL)corporate completion:(void (^)(NSDictionary *))handler{
    
}
///
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
//            NSData *thumbnail = [NSData new];
            NSString *thumbnail = @"";
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
                                if ([[module valueForKey:@"Module"] isKindOfClass:[NSString class]] && [[module valueForKey:@"Module"] isEqualToString:moduleName] && [[module valueForKey:@"Method"] isEqualToString:methodGetFileThumbail]) {
//                                    thumbnail = [[NSData alloc]initWithBase64EncodedString:[module valueForKey:@"Result"] options:0];
                                    thumbnail = [module valueForKey:@"Result"];
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
            handler(thumbnail);
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

@end

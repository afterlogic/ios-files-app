//
//  API.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "ApiP7.h"
#import "Settings.h"
#import "Folder.h"
#import "AFNetworking.h"
#import "NSString+URLEncode.h"
#import <AFNetworking+AutoRetry/AFHTTPRequestOperationManager+AutoRetry.h>

static  int retryCount = 0;
static  int retryCountForFolderUpdate = 0;
static  int retryInterval = 5;
static NSString * errorFieldName = @"ErrorCode";

@import UIKit;

@implementation NSString (NSString_Extended)

//-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
//    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
//                                                                                 (CFStringRef)self,
//                                                                                 NULL,
//                                                                                 (CFStringRef)@"!*'\"();:@&=+$,?%#[]% ",
//                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding)));
//}

//- (NSString *)urlencode {
//    NSMutableString *output = [NSMutableString string];
//    const unsigned char *source = (const unsigned char *)[self UTF8String];
//    int sourceLen = strlen((const char *)source);
//    for (int i = 0; i < sourceLen; ++i) {
//        const unsigned char thisChar = source[i];
//        if (thisChar == ' '){
//            [output appendString:@"+"];
//        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
//                   (thisChar >= 'a' && thisChar <= 'z') ||
//                   (thisChar >= 'A' && thisChar <= 'Z') ||
//                   (thisChar >= '0' && thisChar <= '9')) {
//            [output appendFormat:@"%c", thisChar];
//        } else {
//            [output appendFormat:@"%%%02X", thisChar];
//        }
//    }
//    return output;
//}

@end;

@interface ApiP7 (){
//    AFHTTPreqst *manager;
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation ApiP7

static NSString *appDataAction		= @"SystemGetAppData";
static NSString *signInAction		= @"SystemLogin";
static NSString *isAuhtCheck		= @"SystemIsAuth";
static NSString *filesAction        = @"Files";
static NSString *deleteFiles        = @"FilesDelete";
static NSString *createFolder       = @"FilesFolderCreate";
static NSString *renameFolder       = @"FilesRename";
static NSString *folderInfo         = @"FileInfo";
static NSString *publicLink         = @"FilesCreatePublicLink";
static NSString *logOutAction       = @"SystemLogout";

-(id)init{
    self=[super init];
    if (self) {
        manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [storage cookies]) {
            [storage deleteCookie:cookie];
        }
        
//        retryCount = 3;
    }
    return self;
}

+ (NSDictionary*)requestParams
{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    if ([Settings token])
    {
        [dict setValue:[Settings token] forKey:@"Token"];
    }
    
    if ([Settings authToken])
    {
        [dict setValue:[Settings authToken] forKey:@"AuthToken"];
    }
    
    if ([[Settings currentAccount] integerValue] != 0)
    {
        [dict setValue:[Settings currentAccount] forKey:@"AccountID"];
    }
    
    return dict;
}


+ (instancetype) sharedInstance
{
    static ApiP7 *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ApiP7 alloc] init];
    });
    return sharedInstance;
}

- (NSURLRequest*)requestWithDictionary:(NSDictionary*) dict
{
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [url scheme];
    if (![Settings domainScheme]) {
        [Settings setDomainScheme:scheme ? [NSString stringWithFormat:@"%@://",scheme]:@"https://"];
    }
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/?/Ajax/",[Settings domainScheme],[Settings domain]]]];
    NSMutableDictionary * newDict = [dict mutableCopy];
    [newDict addEntriesFromDictionary:[ApiP7 requestParams]];
    
    NSMutableString *query = [[NSMutableString alloc] init];
    for (id obj in newDict)
    {
        [query appendString:[NSString stringWithFormat:@"%@=%@&",obj,[newDict valueForKey:obj]]];
    }

    NSData *requestData = [query dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestData];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 20.0f;
    
    return request;
}

- (NSMutableURLRequest*)requestWithUploadUrl:(NSString*)url
{
    NSURL *requestUrl = [NSURL URLWithString:[url urlEncodeUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:requestUrl];
    [request setHTTPMethod:@"PUT"];
    [request setValue:[Settings authToken] forHTTPHeaderField:@"Auth-Token"];

    return request;
}

- (void)getAppDataCompletionHandler:(void (^)(NSDictionary * data, NSError * error)) handler
{
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":appDataAction}];

    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request  success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
        NSError *error;
        NSData *data = [NSData new];
        if ([responseObject isKindOfClass:[NSData class]]) {
            data = responseObject;
        }
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        if (json && [json isKindOfClass:[NSDictionary class]])
        {
            if ([[json valueForKey:@"Result"] isKindOfClass:[NSDictionary class]])
            {
                NSString *token = [json valueForKeyPath:@"Result.Token"];
                if (token.length)
                {
                    [Settings setToken:token];
                    error = nil;
                }
                else
                {
                    if ([(NSDictionary *)json objectForKey:errorFieldName]){
                        NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                        error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                    }else {
                        error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                    }
                }
            }
            else
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }
        }
            if(error){
                handler(nil,error);
                return;
            }
            handler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
         dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            handler(nil,error);
         });
    }];

    [manager.operationQueue addOperation:operation];
}


- (void)findFilesWithPattern:(NSString *)searchPattern type:(NSString *)type completion:(void (^)(NSDictionary *data, NSError *))completionHandler{
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":filesAction,@"Pattern":searchPattern,@"Type": type}];
    
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
            }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                completionHandler(nil,error);
                return ;
            }
            
            completionHandler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            completionHandler(nil, error);
        });
    }autoRetryOf:retryCountForFolderUpdate retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
}

- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type completion:(void (^)(NSDictionary *data, NSError* error))handler
{
    NSString *encodedFolder = [folderName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":filesAction,@"Path":encodedFolder ? encodedFolder : @"", @"Type": type }];

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
            }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(nil,error);
                return ;
            }
            
            handler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            handler(nil, error);
        });
    }autoRetryOf:retryCountForFolderUpdate retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
}

- (void)signInWithEmail:(NSString *)email andPassword:(NSString *)password  loginType:(NSString *) type completion:(void (^)(NSDictionary *data, NSError *error))handler
{
    NSDictionary *params = [NSDictionary new];
    NSString *emailUserName = [email componentsSeparatedByString:@"@"].firstObject;
    if([type isEqualToString:@"0"]){
        params = @{@"Action":signInAction,@"Email":email, @"IncPassword":password ,@"SignMe":@"1"};
    }else if([type isEqualToString:@"3"]){
        params = @{@"Action":signInAction,@"IncLogin":emailUserName, @"IncPassword":password,@"SignMe":@"1"};
    }else if([type isEqualToString:@"4"]){
        params = @{@"Action":signInAction,@"IncLogin":emailUserName,@"Email":email, @"IncPassword":password,@"SignMe":@"1"};
    }
        
    NSURLRequest * request = [self requestWithDictionary:params];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSDictionary class]])
                {
                    NSString *token = [json valueForKeyPath:@"Result.AuthToken"];
                    NSNumber * accountID = [json objectForKey:@"AccountID"];
                    if (accountID)
                    {
                        [Settings setCurrentAccount:accountID];
                    }
                    if (token.length)
                    {
                        [Settings setAuthToken:token];
                        error = nil;
                    }
                    else
                    {
                        error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The username or password you entered is incorrect", @"")}];
                }
                if ([(NSDictionary *)json objectForKey:errorFieldName]){
                    NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                }
            }
            handler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            handler(nil,error);
        });
    }autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
}

- (void)signOut:(void(^)(BOOL success, NSError *error))handler{
    NSDictionary *params = [NSDictionary new];
    params = @{@"Action":logOutAction};
    NSURLRequest * request = [self requestWithDictionary:params];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            NSNumber *result;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                result = [NSNumber numberWithBool:[json valueForKey:@"Result"]];
                if ([(NSDictionary *)json objectForKey:errorFieldName]){
                    NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                }
            }
            BOOL success = result.boolValue;
            handler(success,error);

        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"HTTP Request failed: %@", error);
            handler(NO,error);
        });
    } autoRetryOf:retryCount retryInterval:retryInterval];
    [manager.operationQueue addOperation:operation];
}

- (void)checkIsAccountAuthorisedWithCompletion:(void (^)(NSDictionary *data, NSError *error))handler
{
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":isAuhtCheck}];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            handler(json,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (error.code == -1009)
            {
                handler(@{@"Result":@{@"offlineMod":@YES}},nil);
                return ;
            }
            if (error)
            {
                handler(@{}, error);
                return ;
            }
            
            if (error)
            {
                DDLogError(@"%s %@",__PRETTY_FUNCTION__,[error localizedDescription]);
                handler(nil, error);
                return;
            }

        });
    }autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
}

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName isCorporate:(BOOL)corporate atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *data, NSError* error))handler
{
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[ApiP7 requestParams]];
    [newDict setObject:renameFolder forKey:@"Action"];
    [newDict setObject:corporate ? @"corporate" : @"personal" forKey:@"Type"];
    [newDict setObject:[path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] forKey:@"Path"];
    if (isLink)
    {
        [newDict setObject:[[name stringByAppendingString:@".url"]stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] forKey:@"Name"];
    }
    else
    {
        [newDict setObject:[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] forKey:@"Name"];
    }
    [newDict setObject:newName != nil ? [newName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] : @"" forKey:@"NewName"];
    [newDict setObject:[NSNumber numberWithBool:isLink] forKey:@"IsLink"];
    
    NSURLRequest * request = [self requestWithDictionary:newDict];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error = nil;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(nil,error);
                return ;
            }
            handler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(nil,error);
                return ;
            }
        });
    }autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];


}

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(NSDictionary *data, NSError* error))handler
{
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[ApiP7 requestParams]];
    [newDict setObject:createFolder forKey:@"Action"];
    [newDict setObject:corporate ? @"corporate" : @"personal" forKey:@"Type"];
    [newDict setObject:[path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] forKey:@"Path"];
    [newDict setObject:[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] forKey:@"FolderName"];
    DDLogError(@"%@",newDict);
    NSURLRequest * request = [self requestWithDictionary:newDict];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error = nil;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(nil,error);
                return ;
            }
            handler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            DDLogError(@"%@",[error localizedDescription]);
            handler(nil, error);
        });
    }autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];

}

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess, NSError* error))handler
{
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[ApiP7 requestParams]];
    [newDict setObject:deleteFiles forKey:@"Action"];
    NSString * name = folder.name;
    if (folder.isLink.boolValue)
    {
        name = [name stringByAppendingString:@".url"];
    }
    NSString * items = [NSString stringWithFormat:@"[{\"Path\":\"%@\",\"Name\":\"%@\"}]",folder.parentPath ? folder.parentPath : @"", name];
    [newDict setObject:items forKey:@"Items"];
    [newDict setObject:corporate ? @"corporate" : @"personal" forKey:@"Type"];
    [newDict setObject:@"" forKey:@"Path"];
    
    
    NSURLRequest * request = [self requestWithDictionary:newDict];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error = nil;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(NO,error);
                return ;
            }
            handler(YES, error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(NO, error);
                return ;
            }
        });
    }autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
    
    
}

- (void)deleteFiles:(NSArray<Folder *>*)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess, NSError* error))handler
{
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[ApiP7 requestParams]];
    [newDict setObject:deleteFiles forKey:@"Action"];
    
    NSMutableString *itemsForDelet = [[NSMutableString alloc]initWithString:@"["];
    for (Folder *removedItem in files){
        NSString * itemInfo = [NSString stringWithFormat:@"{\"Path\":\"%@\",\"Name\":\"%@\"}",removedItem.fullpath, removedItem.name];
        [itemsForDelet appendString:itemInfo];
        if (![removedItem isEqual:files.lastObject]) {
            [itemsForDelet appendString:@","];
        }
    }
    [itemsForDelet appendString:@"]"];
    
    
    [newDict setObject:itemsForDelet forKey:@"Items"];
    [newDict setObject:corporate ? @"corporate" : @"personal" forKey:@"Type"];
    [newDict setObject:@"" forKey:@"Path"];
    NSURLRequest * request = [self requestWithDictionary:newDict];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error = nil;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(NO,error);
                return ;
            }
            handler(YES, error);
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
    }autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];

}

- (void)getFolderInfoForName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(NSDictionary *data, NSError* error))handler
{
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[ApiP7 requestParams]];
    [newDict setObject:folderInfo forKey:@"Action"];
    
    [newDict setObject:type forKey:@"Type"];
    [newDict setObject:[path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] forKey:@"Path"];
    [newDict setObject:[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] forKey:@"Name"];
    NSURLRequest * request = [self requestWithDictionary:newDict];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error = nil;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(nil,error);
                return ;
            }
            handler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);

                handler(nil,error);
                return ;
            }
        });
    }autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];

}

- (void)putFile:(NSData *)file toFolderPath:(NSString *)folderPath withName:(NSString *)name uploadProgressBlock:(UploadProgressBlock)uploadProgressBlock completion:(void (^)(NSDictionary *data, NSError* error))handler
{
//    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [Settings domainScheme];
    NSString * urlString = [NSString stringWithFormat:@"%@%@/index.php?Upload/File/%@/%@",scheme ? scheme : @"https://",[Settings domain],[folderPath urlEncodeUsingEncoding:NSUTF8StringEncoding],[name urlEncodeUsingEncoding:NSUTF8StringEncoding]];
    DDLogError(@"%@",urlString);
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"PUT"];
    [request setValue:[Settings authToken] forHTTPHeaderField:@"Auth-Token"];
//    NSMutableURLRequest * request = [self requestWithUploadUrl:urlString];
    [request setHTTPBodyStream:[[NSInputStream alloc]initWithData:file]];
//    [request setValue:@"corporate" forHTTPHeaderField:@"Type"];
//    [request setValue:@"{\"Type\":\"corporate\"}" forHTTPHeaderField:@"AdditionalData"];
    
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
            }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(nil,error);
                return ;
            }
            handler(json,nil);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                handler(nil,error);
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


-(void)getPublicLinkForFileNamed:(NSString *)name filePath:(NSString *)filePath type:(NSString *)type size:(NSString *)size isFolder:(BOOL)isFolder completion:(void (^)(NSString *data, NSError* error))completion{
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[ApiP7 requestParams]];
    [newDict setObject:publicLink forKey:@"Action"];
    
    [newDict setObject:type forKey:@"Type"];
    [newDict setObject:filePath forKey:@"Path"];
    [newDict setObject:name forKey:@"Name"];
    [newDict setObject:size forKey:@"Size"];
    [newDict setObject:[NSNumber numberWithBool:isFolder].stringValue forKey:@"IsFolder"];
    NSURLRequest * request = [self requestWithDictionary:newDict];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error = nil;
            NSData *data = [NSData new];
            NSString *result = [NSString new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json objectForKey:@"Result"] isKindOfClass:[NSString class]]) {
                    result = [json objectForKey:@"Result"];
                }else if ([(NSDictionary *)json objectForKey:errorFieldName]){
                    NSNumber * errorCode = [(NSDictionary *)json objectForKey:errorFieldName];
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                }else{
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                }
            }else{
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);
                completion(nil,error);
                return ;
            }

            completion(result,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (error)
            {
                DDLogError(@"%@",[error localizedDescription]);

                completion(nil,error);
                return ;
            }
        });
    }autoRetryOf:retryCount retryInterval:retryInterval];
    
    [manager.operationQueue addOperation:operation];
    

}

-(void)cancelAllOperations{
    [manager.operationQueue cancelAllOperations];
    retryCount = 0;
}

@end

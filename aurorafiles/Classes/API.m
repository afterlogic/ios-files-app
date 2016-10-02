//
//  API.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "API.h"
#import "Settings.h"
#import "Folder.h"

@import UIKit;

@implementation NSString (NSString_Extended)

-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding)));
}

- (NSString *)urlencode {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[self UTF8String];
    int sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

@end;

@implementation API

static NSString *appDataAction		= @"SystemGetAppData";
static NSString *signInAction		= @"SystemLogin";
static NSString *isAuhtCheck		= @"SystemIsAuth";
static NSString *filesAction        = @"Files";
static NSString *deleteFiles        = @"FilesDelete";
static NSString *createFolder       = @"FilesFolderCreate";
static NSString *renameFolder       = @"FilesRename";
static NSString *folderInfo         = @"FileInfo";

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
    static API *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[API alloc] init];
    });
    return sharedInstance;
}

- (NSURLRequest*)requestWithDictionary:(NSDictionary*) dict
{
    BOOL hasPrefix = [[Settings domain] containsString:@"https://"];
    if (!hasPrefix) {
        hasPrefix = [[Settings domain] containsString:@"http://"];
    }
    
    
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [url scheme];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/?/Ajax/",scheme ? @"" : @"https://",[Settings domain]]]];
    NSMutableDictionary * newDict = [dict mutableCopy];
    [newDict addEntriesFromDictionary:[API requestParams]];
    
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

- (NSMutableURLRequest*) requestWithUploadUrl:(NSString*)url
{
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"PUT"];
    [request setValue:[Settings authToken] forHTTPHeaderField:@"Auth-Token"];

    return request;
}


- (void)getAppDataCompletionHandler:(void (^)(NSDictionary * data, NSError * error)) handler
{
    
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":appDataAction}];
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            if (error) {
                handler(@{},error);
                return ;
            }
            NSError * error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if ([json isKindOfClass:[NSDictionary class]])
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
                        error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                }
            }
            handler(json,error);        
        });
    }];
    [task resume];
}

- (void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type completion:(void (^)(NSDictionary *))handler
{

    
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":filesAction,@"Path":folderName ? folderName : @"", @"Type": type }];
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            
            NSError * error = nil;
            if (data)
            {
                id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                
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
            }
            else
            {
                handler(nil);
            }
        });
    }];
    [task resume];

}

- (void)signInWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(NSDictionary *data, NSError *error))handler
{
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":signInAction,@"Email":email, @"IncPassword":password}];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            
            
            NSError * error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
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
            }
            handler(json,error);
        
        });
    }];
    [task resume];
}

- (void)checkIsAccountAuthorisedWithCompletion:(void (^)(NSDictionary *, NSError *))handler
{
    
    
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":isAuhtCheck}];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error){
        dispatch_async(dispatch_get_main_queue(), ^() {
            
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
            NSError * error = nil;
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
            if (error)
            {
                NSLog(@"%s %@",__PRETTY_FUNCTION__,[error localizedDescription]);
                handler(nil, error);
                return;
            }
            
            handler (json, nil);
        
        });
    }];
    [task resume];
}

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(NSDictionary *))handler
{
    
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[API requestParams]];
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
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSLog(@"%@",newDict);
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            
            NSError * error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
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
    }];
    [task resume];

}

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName isCorporate:(BOOL)corporate atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *))handler
{
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[API requestParams]];
    [newDict setObject:renameFolder forKey:@"Action"];
    [newDict setObject:corporate ? @"corporate" : @"personal" forKey:@"Type"];
    [newDict setObject:path forKey:@"Path"];
    if (isLink)
    {
        [newDict setObject:[name stringByAppendingString:@".url"] forKey:@"Name"];
    }
    else
    {
        [newDict setObject:name forKey:@"Name"];
    }
    [newDict setObject:newName forKey:@"NewName"];
    [newDict setObject:[NSNumber numberWithBool:isLink] forKey:@"IsLink"];
    
    NSURLRequest * request = [self requestWithDictionary:newDict];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            
            NSError * error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
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
    }];
    [task resume];

}

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(NSDictionary *))handler
{
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[API requestParams]];
    [newDict setObject:createFolder forKey:@"Action"];
    [newDict setObject:corporate ? @"corporate" : @"personal" forKey:@"Type"];
    [newDict setObject:path forKey:@"Path"];
    [newDict setObject:name forKey:@"FolderName"];
    NSLog(@"%@",newDict);
    NSURLRequest * request = [self requestWithDictionary:newDict];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            
            NSError * error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
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
    }];
    [task resume];
}

- (void)deleteFiles:(NSDictionary *)files isCorporate:(BOOL)corporate completion:(void (^)(NSDictionary *))handler
{
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[API requestParams]];
    [newDict setObject:deleteFiles forKey:@"Action"];
    NSString * items = [NSString stringWithFormat:@"[{\"Path\":\"%@\",\"Name\":\"%@\"}]",[files objectForKey:@"Path"], [files objectForKey:@"Name"]];
    [newDict setObject:items forKey:@"Items"];
    [newDict setObject:corporate ? @"corporate" : @"personal" forKey:@"Type"];
    [newDict setObject:@"" forKey:@"Path"];
    NSURLRequest * request = [self requestWithDictionary:newDict];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            
            NSError * error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
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
    }];
    [task resume];
}

- (void)getFolderInfoForName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(NSDictionary *))handler
{
    
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[API requestParams]];
    [newDict setObject:folderInfo forKey:@"Action"];
    
    [newDict setObject:type forKey:@"Type"];
    [newDict setObject:path forKey:@"Path"];
    [newDict setObject:name forKey:@"Name"];
    NSURLRequest * request = [self requestWithDictionary:newDict];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            
            NSError * error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            
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
    }];
    [task resume];
}

- (void)putFile:(NSData *)file toFolderPath:(NSString *)folderPath withName:(NSString *)name completion:(void (^)(NSDictionary *))handler
{
    
    NSString * urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[Settings domain],[folderPath urlEncodeUsingEncoding:NSUTF8StringEncoding],name];
    NSLog(@"%@",urlString);
    NSMutableURLRequest * request = [self requestWithUploadUrl:urlString];
    [request setHTTPBodyStream:[[NSInputStream alloc]initWithData:file]];
    [request setValue:@"corporate" forHTTPHeaderField:@"Type"];
    [request setValue:@"{\"Type\":\"corporate\"}" forHTTPHeaderField:@"AdditionalData"];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            
            NSError * error = nil;
            
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
    }];
    [task resume];

}

@end

//
//  API.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "API.h"
#import "Settings.h"
@import UIKit;

@implementation API

static NSString *appDataAction		= @"SystemGetAppData";
static NSString *signInAction		= @"SystemLogin";
static NSString *isAuhtCheck		= @"SystemIsAuth";
static NSString *filesAction        = @"Files";
static NSString *deleteFiles        = @"FilesDelete";

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
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/?/Ajax/",[Settings domain]]]];
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



- (void)getAppDataCompletionHandler:(void (^)(NSDictionary * data, NSError * error)) handler
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":appDataAction}];
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
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

- (void)getFilesForFolder:(NSString *)folderName isCorporate:(BOOL)corporate completion:(void (^)(NSDictionary *))handler
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":filesAction,@"Path":folderName ? folderName : @"", @"Type": corporate ? @"corporate" : @"personal"}];
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
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

- (void)signInWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(NSDictionary *data, NSError *error))handler
{
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":signInAction,@"Email":email, @"IncPassword":password}];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
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
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                }
            }
            handler(json,error);
        
        });
    }];
    [task resume];
}

- (void)checkIsAccountAuthorisedWithCompletion:(void (^)(NSDictionary *, NSError *))handler
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLRequest * request = [self requestWithDictionary:@{@"Action":isAuhtCheck}];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error){
        dispatch_async(dispatch_get_main_queue(), ^() {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

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

- (void)deleteFiles:(NSDictionary *)files isCorporate:(BOOL)corporate completion:(void (^)(NSDictionary *))handler
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/?/Ajax/Action=%@&",[Settings domain],deleteFiles]]];
    NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:[API requestParams]];
    
    NSMutableString *query = [[NSMutableString alloc] init];
    for (id obj in newDict)
    {
        [query appendString:[NSString stringWithFormat:@"%@=%@&",obj,[newDict valueForKey:obj]]];
    }
    [query appendString:[NSString stringWithFormat:@"Items=[{\"Path\":\"%@\",\"Name\":\"%@\"}]",[files objectForKey:@"Path"],[files objectForKey:@"Name"]]];
    [query appendString:[NSString stringWithFormat:@"&Type=%@",corporate ? @"corporate" : @"personal"]];
    [query appendString:@"&Path=\"\""];
    NSData *requestData = [query dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestData];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 20.0f;
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
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


@end

//
//  NSURLRequest+requestGenerator.m
//  aurorafiles
//
//  Created by Cheshire on 18.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "NSURLRequest+requestGenerator.h"
#import "Settings.h"
#import "Folder.h"

@implementation NSURLRequest (requestGenerator)

//+(NSURLRequest *)requestWithDictionary:(NSDictionary *)dict{
//    NSURLRequest * request = [NSURLRequest new];
//    if ([Settings isPEight]) {
//        request = [NSURLRequest p8RequestWithDictionary:dict];
//    }else{
//        request = [NSURLRequest p7RequestWithDictionary:dict];
//    }
//    return request;
//}


+(NSURLRequest*)p7RequestWithDictionary:(NSDictionary*) dict
{
    BOOL hasPrefix = [[Settings domain] containsString:@"https://"];
    if (!hasPrefix) {
        hasPrefix = [[Settings domain] containsString:@"http://"];
    }
    
    
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [url scheme];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/?/Ajax/",scheme ? @"" : @"https://",[Settings domain]]]];
    NSMutableDictionary * newDict = [dict mutableCopy];
    [newDict addEntriesFromDictionary:[NSURLRequest requestParams]];
    
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

+(NSURLRequest*)p8RequestWithDictionary:(NSDictionary*) dict
{
    BOOL hasPrefix = [[Settings domain] containsString:@"https://"];
    if (!hasPrefix) {
        hasPrefix = [[Settings domain] containsString:@"http://"];
    }
    
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [url scheme];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/?Api=",scheme ? @"" : @"https://",[Settings domain]]]];
    
    NSMutableDictionary * newDict = [dict mutableCopy];
    [newDict addEntriesFromDictionary:[NSURLRequest requestParams]];
    
    NSMutableString *query = [[NSMutableString alloc] init];
    for (id obj in newDict)
    {
        if ([[newDict valueForKey:obj] isKindOfClass:[NSDictionary class]]) {
            NSString *sameString = [NSURLRequest stringParamsFromDict:[newDict valueForKey:obj]];
            [query appendString:[NSString stringWithFormat:@"%@=%@&",obj,sameString]];
        }else{
            [query appendString:[NSString stringWithFormat:@"%@=%@&",obj,[newDict valueForKey:obj]]];
        }
        
    }
    
    NSData *requestData = [query dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestData];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 20.0f;
    
    return request;
}

+(NSURLRequest*)p8DownloadRequestWithDictionary:(NSDictionary*) dict
{
    BOOL hasPrefix = [[Settings domain] containsString:@"https://"];
    if (!hasPrefix) {
        hasPrefix = [[Settings domain] containsString:@"http://"];
    }
    
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString * scheme = [url scheme];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/?Api=",scheme ? @"" : @"https://",[Settings domain]]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:20];
    
    NSMutableDictionary * newDict = [dict mutableCopy];
    [newDict addEntriesFromDictionary:[NSURLRequest requestParams]];
    
    NSMutableString *query = [[NSMutableString alloc] init];
    for (id obj in newDict)
    {
        if ([[newDict valueForKey:obj] isKindOfClass:[NSDictionary class]]) {
            NSString *sameString = [NSURLRequest stringParamsFromDict:[newDict valueForKey:obj]];
            [query appendString:[NSString stringWithFormat:@"%@=%@&",obj,sameString]];
        }else{
            [query appendString:[NSString stringWithFormat:@"%@=%@&",obj,[newDict valueForKey:obj]]];
        }
        
    }
    
    NSData *requestData = [query dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestData];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 20.0f;
    
    return request;
}

+(NSString *)stringParamsFromDict:(NSDictionary *)dict{
    NSString *string = @"";
    NSMutableArray *resultArr = [NSMutableArray new];
    for (id obj in dict){
        NSLog(@"%@", obj);
        if ([[dict valueForKey:obj] isKindOfClass:[NSString class]]) {
            [resultArr addObject:[NSString stringWithFormat:@"\"%@\":\"%@\"",obj,[dict valueForKey:obj]]];
        }else if([[dict valueForKey:obj] isKindOfClass:[NSDictionary class]]){
            [resultArr addObject:[NSString stringWithFormat:@"\"%@\":\"%@\"",obj,[NSURLRequest stringParamsFromDict:[dict valueForKey:obj]]]];
        }else if([[dict valueForKey:obj] isKindOfClass:[NSArray class]]){
            [resultArr addObject:[NSString stringWithFormat:@"\"%@\":%@",obj,[NSURLRequest generateItemsStringFromFilesArray:[dict valueForKey:obj]]]];
        }
    }
    string = [NSString stringWithFormat:@"{%@}",[resultArr componentsJoinedByString:@","]];
    return string;
}

+ (NSString *)generateItemsStringFromFilesArray:(NSArray *)files{
    NSMutableArray *resultArr = [NSMutableArray new];
    for (id item in files) {
        if ([item isKindOfClass:[Folder class]]) {
            NSMutableString *params = @"".mutableCopy;
            params = [NSString stringWithFormat:@"{\"Path\":\"%@\",\"Name\":\"%@\"}",[(Folder *)item parentPath].length ? [(Folder *)item parentPath] : @"",[(Folder *)item name]].mutableCopy;
            [resultArr addObject:params];
        }
    }
    NSString *result = [NSString stringWithFormat:@"[%@]",[resultArr componentsJoinedByString:@","]];
    return result;
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


@end

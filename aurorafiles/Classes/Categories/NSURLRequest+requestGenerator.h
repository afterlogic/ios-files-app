//
//  NSURLRequest+requestGenerator.h
//  aurorafiles
//
//  Created by Cheshire on 18.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (requestGenerator)
+(NSURLRequest*)p8RequestWithDictionary:(NSDictionary*) dict;
+(NSURLRequest*)p8DownloadRequestWithDictionary:(NSDictionary*) dict;
+(NSString *)stringParamsFromDict:(NSDictionary *)dict;
@end

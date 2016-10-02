//
//  NSString+URLEncode.m
//  aurorafiles
//
//  Created by Cheshire on 02.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "NSString+URLEncode.h"

@implementation NSString (URLEncode)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding)));
}
@end

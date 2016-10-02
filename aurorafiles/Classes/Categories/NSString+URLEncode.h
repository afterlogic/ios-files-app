//
//  NSString+URLEncode.h
//  aurorafiles
//
//  Created by Cheshire on 02.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLEncode)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
@end

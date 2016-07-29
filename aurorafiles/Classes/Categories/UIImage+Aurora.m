//
//  UIImage+Aurora.m
//  aurorafiles
//
//  Created by Michael Akopyants on 25/02/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "UIImage+Aurora.h"

@implementation UIImage (Aurora)
+ (UIImage*)assetImageForContentType:(NSString *)contentType
{
    if ([contentType isEqualToString:@"application/pdf"])
    {
        return [UIImage imageNamed:@"pdf"];
    }
    if ([contentType isEqualToString:@"image/png"])
    {
        return [UIImage imageNamed:@"png"];
    }
    if ([contentType isEqualToString:@"image/vnd.adobe.photoshop"])
    {
        return [UIImage imageNamed:@"psd"];
    }
    if ([contentType isEqualToString:@"image/jpg"] || [contentType isEqualToString:@"image/jpeg"])
    {
        return [UIImage imageNamed:@"jpg"];
    }
    
    if ([contentType isEqualToString:@"application/msword"])
    {
        return [UIImage imageNamed:@"doc"];
    }
    
    if ([contentType isEqualToString:@"application/excel"])
    {
        return [UIImage imageNamed:@"xls"];
    }
    
    if ([contentType isEqualToString:@"audio/mpeg"])
    {
        return [UIImage imageNamed:@"audio"];
    }
    if ([contentType isEqualToString:@"text/plain"])
    {
        return [UIImage imageNamed:@"txt"];
    }
    
    if ([contentType isEqualToString:@"application/zip"])
    {
        return [UIImage imageNamed:@"zip"];
    }
    
    if ([contentType isEqualToString:@"text/vcard"])
    {
        return [UIImage imageNamed:@"vcard"];
    }
    if ([contentType isEqualToString:@"application/postscript"])
    {
        return [UIImage imageNamed:@"settings"];
    }
    
    if ([contentType isEqualToString:@"application/vnd.ms-powerpoint"])
    {
        return [UIImage imageNamed:@"ppt"];
    }
    return [UIImage imageNamed:@"other"];
}
@end

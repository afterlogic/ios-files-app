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
    
    if ([contentType isEqualToString:@"video/quicktime"])
    {
        return [UIImage imageNamed:@"video"];
    }
    return [UIImage imageNamed:@"other"];
}

- (UIImage *)fixOrientation {
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
@end

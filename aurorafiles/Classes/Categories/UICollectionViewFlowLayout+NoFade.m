//
//  UICollectionViewFlowLayout+NoFade.m
//  aurorafiles
//
//  Created by Cheshire on 14.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "UICollectionViewFlowLayout+NoFade.h"
#import <objc/runtime.h>

@implementation UICollectionViewFlowLayout (NoFade)

+ (void) load
{
    Method original, swizzled;
    
    original = class_getInstanceMethod(self, @selector(initialLayoutAttributesForAppearingItemAtIndexPath:));
    swizzled = class_getInstanceMethod(self, @selector(noFadeInitialLayoutAttributesForAppearingItemAtIndexPath:));
    
    method_exchangeImplementations(original, swizzled);
    
    original = class_getInstanceMethod(self, @selector(finalLayoutAttributesForDisappearingItemAtIndexPath:));
    swizzled = class_getInstanceMethod(self, @selector(noFadeFinalLayoutAttributesForDisappearingItemAtIndexPath:));
    
    method_exchangeImplementations(original, swizzled);
}

- (UICollectionViewLayoutAttributes *)noFadeInitialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // Not recursive, due to method exhange in load above
    // This is because we can't call super in a catagory
    UICollectionViewLayoutAttributes * attributes = [self noFadeInitialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    
    attributes.alpha = 1.0;
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)noFadeFinalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // Not recursive, due to method exhange in load above
    // This is because we can't call super in a catagory
    UICollectionViewLayoutAttributes * attributes = [self noFadeFinalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    attributes.alpha = 1.0;
    
    return attributes;
}

@end

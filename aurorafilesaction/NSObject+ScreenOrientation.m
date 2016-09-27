//
//  NSObject+ScreenOrientation.m
//  aurorafiles
//
//  Created by Cheshire on 28.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NSObject+ScreenOrientation.h"

@implementation NSObject (ScreenOrientation)
+ (InterfaceOrientationType)orientation{
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize nativeSize = [UIScreen mainScreen].currentMode.size;
    CGSize sizeInPoints = [UIScreen mainScreen].bounds.size;
    
    InterfaceOrientationType result;
    
    if(scale * sizeInPoints.width == nativeSize.width){
        result = InterfaceOrientationTypePortrait;
    }else{
        result = InterfaceOrientationTypeLandscape;
    }
    
    return result;
}

@end

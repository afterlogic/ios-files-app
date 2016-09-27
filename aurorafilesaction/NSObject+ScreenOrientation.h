//
//  NSObject+ScreenOrientation.h
//  aurorafiles
//
//  Created by Cheshire on 28.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, InterfaceOrientationType) {
    InterfaceOrientationTypePortrait = 1,
    InterfaceOrientationTypeLandscape = 3
};

@interface NSObject (ScreenOrientation)
+ (InterfaceOrientationType)orientation;
@end

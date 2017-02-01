//
//  GalleryPageDelegate.h
//  aurorafiles
//
//  Created by Cheshire on 17.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImageViewController;

@protocol GalleryPageDelegate <NSObject>

-(void)setCurrentPageController:(ImageViewController *)page;
@end

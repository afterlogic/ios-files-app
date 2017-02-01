//
//  FileGalleryPageViewController.h
//  aurorafiles
//
//  Created by Cheshire on 16.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GalleryPageDelegate.h"

static NSString * const SYPhotoBrowserHideNavbarNotification   = @"SYPhotoBrowserHideNavbarNotification";
static NSString * const SYPhotoBrowserLongPressNotification = @"SYPhotoBrowserLongPressNotification";
static NSString * const SYPhotoBrowserDismissNotification = @"SYPhotoBrowserDismissNotification";
@class Folder;
@interface FileGalleryPageViewController : UIPageViewController

@property (strong, nonatomic) id<GalleryPageDelegate> pageDelegate;
@property (strong, nonatomic) NSArray<Folder *>* itemsList;
@property (nonatomic, assign) NSUInteger initialPageIndex;
@property (nonatomic, assign) BOOL enableStatusBarHidden;

- (instancetype)initWithImageSourceArray:(NSArray<Folder *>*)imageSourceArray;

@end

//
//  ImageViewController.h
//  aurorafiles
//
//  Created by Cheshire on 16.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Folder.h"

@interface ImageViewController : UIViewController

@property (strong, nonatomic) Folder *item;
@property (nonatomic, assign) NSUInteger pageIndex;
@property (strong, nonatomic) UIImageView *imageView;

- (void)resetImageSize;
- (void)hideHud;
@end

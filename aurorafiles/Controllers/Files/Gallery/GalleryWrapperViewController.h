//
//  GalleryWrapperViewController.h
//  aurorafiles
//
//  Created by Cheshire on 17.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Folder;

@interface GalleryWrapperViewController : UIViewController

@property (strong, nonatomic) NSArray<Folder *>* itemsList;
@property (nonatomic, assign) NSUInteger initialPageIndex;

@end

//
//  FileGalleryCollectionViewController.h
//  aurorafiles
//
//  Created by Michael Akopyants on 24/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Folder.h"

@interface FileGalleryCollectionViewController : UICollectionViewController
@property (strong, nonatomic) Folder * folder;
@property (strong, nonatomic) Folder * currentItem;
@property (weak, nonatomic) UIImageView * backgroundImageView;
@property (strong, nonatomic) UIImage *snapshot;
@end

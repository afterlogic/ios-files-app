//
//  EXPreviewFileGalleryCollectionViewController.h
//  aurorafiles
//
//  Created by Cheshire on 27.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UploadedFile.h"


@interface EXPreviewFileGalleryCollectionViewController : UICollectionViewController
@property (strong, nonatomic) UploadedFile * folder;
@property (strong, nonatomic) UploadedFile * currentItem;
@property (strong, nonatomic) NSArray * items;

- (void)highlightItem:(UploadedFile *)item;
@end

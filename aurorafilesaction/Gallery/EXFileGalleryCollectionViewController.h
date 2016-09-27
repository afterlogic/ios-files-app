//
//  FileGalleryCollectionViewController.h
//  aurorafiles
//
//  Created by Michael Akopyants on 24/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UploadedFile.h"
@protocol GalleryDelegate
@required
-(void)selectGalleryItemAtIndex:(int)idx;
@end

@interface EXFileGalleryCollectionViewController : UICollectionViewController
@property (strong, nonatomic) UploadedFile * folder;
@property (strong, nonatomic) UploadedFile * currentItem;
@property (weak, nonatomic) UIImageView * backgroundImageView;
@property (strong, nonatomic) UIImage *snapshot;
@property (strong, nonatomic) NSArray * items;
@property (nonatomic, assign) id <GalleryDelegate> delegate;
@end

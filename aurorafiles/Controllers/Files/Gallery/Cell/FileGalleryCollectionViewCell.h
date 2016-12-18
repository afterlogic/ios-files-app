//
//  FileGalleryCollectionViewCell.h
//  aurorafiles
//
//  Created by Michael Akopyants on 24/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Folder;
@interface FileGalleryCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) Folder * file;
@property (strong, nonatomic) UITapGestureRecognizer * doubleTap;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
+ (NSString*)cellId;
+ (CGSize)cellSize;
+ (CGSize)cellSizeLandscape;
@end

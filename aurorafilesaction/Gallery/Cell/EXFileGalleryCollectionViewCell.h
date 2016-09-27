//
//  FileGalleryCollectionViewCell.h
//  aurorafiles
//
//  Created by Michael Akopyants on 24/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>
@class UploadedFile;
@interface EXFileGalleryCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) UploadedFile * file;
@property (strong, nonatomic) UITapGestureRecognizer * doubleTap;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
+ (NSString*)cellId;

@end

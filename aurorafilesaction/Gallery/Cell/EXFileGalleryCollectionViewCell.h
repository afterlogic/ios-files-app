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
@property (weak, nonatomic) IBOutlet UIView *webContainerView;
@property (weak, nonatomic) IBOutlet UILabel *pageName;
@property (weak, nonatomic) IBOutlet UILabel *pageLink;
@property (weak, nonatomic) IBOutlet UILabel *pageDescription;
@property (weak, nonatomic) IBOutlet UIImageView *pagePreview;

+ (NSString*)cellId;

@end

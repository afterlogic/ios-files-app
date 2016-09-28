//
//  EXPreviewFileGalleryCollectionViewCell.h
//  aurorafiles
//
//  Created by Cheshire on 27.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
@class UploadedFile;
@interface EXPreviewFileGalleryCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) UploadedFile * file;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *selectedView;
+ (NSString*)cellId;
@end

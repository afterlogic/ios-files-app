//
//  EXPreviewFileGalleryCollectionViewCell.m
//  aurorafiles
//
//  Created by Cheshire on 27.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "EXPreviewFileGalleryCollectionViewCell.h"
#import "UIImage+ImageCompress.h"
#import "UploadedFile.h"

@interface EXPreviewFileGalleryCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@end

@implementation EXPreviewFileGalleryCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
}

- (void)setFile:(UploadedFile *)file
{
    _file = file;
    if (file)
    {
        [self.activityView startAnimating];
    
        self.imageView.userInteractionEnabled = YES;
        self.imageView.alpha = 0.0f;
        
        NSLog(@"%@",[file path]);
        self.imageView.image = nil;
        UIImage * image = nil;
        
        //NSData *imageData = [NSData dataWithContentsOfURL:[file path]];
        if ([file.type isEqualToString:@"public.image"]) {
            NSString *path = file.path.absoluteString;
            image = [UIImage imageWithContentsOfFile: [path stringByReplacingOccurrencesOfString:@"file://" withString:@""]];
            self.imageView.image = [UIImage compressImage:image compressRatio:0.1];
            image = nil;
        }
        if ([file.type isEqualToString:@"public.url"]) {
            image = [UIImage imageNamed:@"shotcut"];
            self.imageView.image = [UIImage compressImage:image compressRatio:0.1];
            image = nil;
        }
        
        if ([file.type isEqualToString:@"public.movie"]) {
            image = [UIImage imageNamed:@"video"];
            self.imageView.image = [UIImage compressImage:image compressRatio:0.1];
            image = nil;
        }
        
        self.imageView.alpha = 1.0f;
        [self.activityView stopAnimating];
        self.activityView.alpha = 0.0f;
        self.selectedView.hidden = NO;
    }
}

-(void)setSelected:(BOOL)selected{
    if (selected) {
        self.selectedView.hidden = NO;
    }else{
        self.selectedView.hidden = YES;
    }
}

+ (NSString*)cellId
{
    return @"EXPreviewFileGalleryCollectionViewCell";
}


@end

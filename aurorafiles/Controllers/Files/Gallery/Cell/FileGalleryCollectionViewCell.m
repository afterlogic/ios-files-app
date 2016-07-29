//
//  FileGalleryCollectionViewCell.m
//  aurorafiles
//
//  Created by Michael Akopyants on 24/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "FileGalleryCollectionViewCell.h"
#import "Folder.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface FileGalleryCollectionViewCell () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;


@end

@implementation FileGalleryCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 5;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;    
    self.scrollView.delegate = self;
    // Initialization code
}



- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
}

- (void)setFile:(Folder *)file
{
    _file = file;
    if (file)
    {
        [self.activityView startAnimating];
        UITapGestureRecognizer * zoomOn = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomImageIn:)];

        zoomOn.numberOfTapsRequired = 2;
        zoomOn.numberOfTouchesRequired = 1;
        self.doubleTap = zoomOn;
        [self.imageView addGestureRecognizer:self.doubleTap];
        self.imageView.userInteractionEnabled = YES;
        self.imageView.alpha = 0.0f;
        
        NSLog(@"%@",[file viewLink]);
        self.imageView.image = nil;
        UIImage * image = nil;
        if (file.isDownloaded.boolValue)
        {
            NSString * string = [[[file downloadURL] URLByAppendingPathComponent:file.name] absoluteString];
            NSFileManager * manager = [NSFileManager defaultManager];
            if ([manager fileExistsAtPath:string])
            {
                NSLog(@"exist");
            }
            image = [UIImage imageWithData:[NSData dataWithContentsOfFile:string]];
        }
        if (!image)
        {
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:[file viewLink]] placeholderImage:nil options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
                self.imageView.alpha = 1.0f;
                [self.activityView stopAnimating];
                CGFloat minScale = 1;
                self.scrollView.minimumZoomScale = minScale;
                
                // 5
                self.scrollView.maximumZoomScale = 5.0f;
                self.scrollView.zoomScale = minScale;
            }];
        }
        else
        {
            self.imageView.image = image;
            self.imageView.alpha = 1.0f;
            [self.activityView stopAnimating];
            CGFloat minScale = 1;
            self.scrollView.minimumZoomScale = minScale;
            
            // 5
            self.scrollView.maximumZoomScale = 5.0f;
            self.scrollView.zoomScale = minScale;
        }
        
    }
}

+ (NSString*)cellId
{
    return @"FileGalleryCollectionViewCellId";
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = [[self viewForZoomingInScrollView:self.scrollView] frame].size.height / scale;
    zoomRect.size.width  = [[self viewForZoomingInScrollView:self.scrollView] frame].size.width  / scale;
    
    center = [[self viewForZoomingInScrollView:self.scrollView] convertPoint:center fromView:self];
    
    zoomRect.origin.x    = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = center.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

- (void)zoomImageIn:(UITapGestureRecognizer*)recognizer{
    
    float newScale = self.scrollView.zoomScale * 4.0;
    
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale)
    {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
    else
    {
        CGRect zoomRect = [self zoomRectForScale:newScale
                                      withCenter:[recognizer locationInView:recognizer.view]];
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
}

@end

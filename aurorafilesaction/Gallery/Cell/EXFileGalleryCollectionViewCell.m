//
//  FileGalleryCollectionViewCell.m
//  aurorafiles
//
//  Created by Michael Akopyants on 24/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "EXFileGalleryCollectionViewCell.h"
#import "UploadedFile.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "LKLinkPreviewKit.h"
#import "UIImage+ImageCompress.h"
#import <MobileCoreServices/MobileCoreServices.h>


@interface EXFileGalleryCollectionViewCell () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;


@end

@implementation EXFileGalleryCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 5;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.pagePreview.contentMode = UIViewContentModeScaleAspectFit;
    self.pageLink.text = @"";
    self.pageName.text = @"";
    self.pageDescription.text = @"";
    self.webContainerView.alpha = 0.0f;
    self.scrollView.delegate = self;

    // Initialization code
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
        if ([file.type isEqualToString:(NSString *)kUTTypeURL]) {
                [LKLinkPreviewReader linkPreviewFromURL:file.webPageLink completionHandler:^(NSArray *previews, NSError *error) {
                    if (previews.count > 0  && ! error) {
                        NSMutableString *text = [NSMutableString new];
                        for (LKLinkPreview *preview in previews) {
                            [text appendFormat:@"%@\n", [preview description]];
                        }
                        NSLog(@"%@",text);
                        LKLinkPreview *preview = previews.firstObject;
                        self.pageName.text = preview.title;
                        self.pageLink.text = file.webPageLink.absoluteString;
                        //                    self.pageDescription.text = preview.linkDescription;
                        
                        if (preview.imageURL){
                            [self.pagePreview sd_setImageWithURL:preview.imageURL placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                if (image) {
                                    self.pagePreview.image = image;
                                }
                                [self webPageEndParsing];
                            }];
                        }else{
                            [self webPageEndParsing];
                        }
                    }
                    else {
                        [self webPageEndParsing];
                    }
                    
                }];
        }else
        {
            UITapGestureRecognizer * zoomOn = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomImageIn:)];

            zoomOn.numberOfTapsRequired = 2;
            zoomOn.numberOfTouchesRequired = 1;
            self.doubleTap = zoomOn;
            [self.imageView addGestureRecognizer:self.doubleTap];
            self.imageView.userInteractionEnabled = YES;
            self.imageView.alpha = 0.0f;
            
            NSLog(@"%@",[file path]);
            self.imageView.image = nil;
            UIImage * image = nil;
            
            NSString *path = file.path.absoluteString;
            image = [UIImage imageWithContentsOfFile: [path stringByReplacingOccurrencesOfString:@"file://" withString:@""]];
            self.imageView.image = [UIImage compressImage:image compressRatio:0.1];
            image = nil;
            self.imageView.alpha = 1.0f;
            [self.activityView stopAnimating];
            CGFloat minScale = 1;
            self.scrollView.minimumZoomScale = minScale;
            
            // 5
            self.scrollView.maximumZoomScale = 5.0f;
            self.scrollView.zoomScale = minScale;
            self.activityView.alpha = 0.0f;
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

- (void)webPageEndParsing{
    self.webContainerView.alpha = 1.0f;
    [self.activityView stopAnimating];
    self.activityView.alpha = 0.0f;
}

//- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
//    self.wevView.alpha = 0.0f;
//    self.webContainerView.alpha = 1.0f;
//    [self.activityView stopAnimating];
//    self.activityView.alpha = 0.0f;
//}

@end

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
#import <SDWebImage/UIImage+MultiFormat.h>
#import "UIImage+Aurora.h"
#import "MBProgressHUD.h"
#import "StorageManager.h"

@interface FileGalleryCollectionViewCell () <UIScrollViewDelegate>{
    MBProgressHUD *hud;
}

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
    self.activityView.hidden = YES;
    hud.hidden = YES;
}



- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
    [self.imageView sd_cancelCurrentImageLoad];
    [hud hideAnimated:YES];
    hud = nil;
    hud.hidden = YES;
}

- (void)setFile:(Folder *)file
{
    hud = [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
    _file = file;
    if (file)
    {
        hud.mode = MBProgressHUDModeDeterminate;
        [hud setBackgroundColor:[UIColor clearColor]];
        
        hud.hidden = NO;
        [hud showAnimated:YES];
        UITapGestureRecognizer * zoomOn = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomImageIn:)];

        zoomOn.numberOfTapsRequired = 2;
        zoomOn.numberOfTouchesRequired = 1;
        self.doubleTap = zoomOn;
        [self.imageView addGestureRecognizer:self.doubleTap];
        self.imageView.userInteractionEnabled = YES;
        self.imageView.alpha = 0.0f;
        self.imageView.image = nil;
        UIImage * image = nil;
        if ([file.isP8 boolValue]) {
            NSLog(@"collection view cell image - > %@",[file content]);
            NSString * thumb = file.content;
            NSData *data;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([thumb length] && [fileManager fileExistsAtPath:thumb]) {
                data= [[NSData alloc]initWithContentsOfFile:thumb];
            }
            if(data){
                UIImage *image = [UIImage imageWithData:data];
                [self.imageView setImage:image];
                [hud hideAnimated:YES];
                hud.hidden = YES;
            }else{
//                __weak typeof(self)weakSelf = self;
                [[StorageManager sharedManager]updateFileView:file type:file.type context:nil withProgress:^(float progress) {
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            hud.progress = progress;
                            NSLog(@"%@ progress -> %f",file.name, progress);
                        });
                } complition:^(UIImage *thumbnail){
                        if (thumbnail) {
                            dispatch_async(dispatch_get_main_queue(), ^(){
                                self.imageView.image = thumbnail;
                                });
                            [hud hideAnimated:YES];
                            hud.hidden = YES;
                        }else{
                            UIImage * placeholder = [UIImage assetImageForContentType:[file validContentType]];
                            if (file.isLink.boolValue && ![file isImageContentType])
                            {
                                placeholder = [UIImage imageNamed:@"shotcut"];
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.imageView.image = placeholder;
                            });
                            [hud hideAnimated:YES];
                            hud.hidden = YES;
                        }
                        [self setNeedsDisplay];
                }];
            }
        }else{
            NSLog(@"collection view cell image - > %@",[file viewLink]);
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
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:[file viewLink]] placeholderImage:nil options:SDWebImageContinueInBackground progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                    hud.progress = (float)receivedSize / file.size.floatValue;
                } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    [hud hideAnimated:YES];
                    hud.hidden = YES;
                    self.imageView.alpha = 1.0f;
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
                [hud hideAnimated:YES];
                hud.hidden = YES;
                CGFloat minScale = 1;
                self.scrollView.minimumZoomScale = minScale;
                
                // 5
                self.scrollView.maximumZoomScale = 5.0f;
                self.scrollView.zoomScale = minScale;
            }
            
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

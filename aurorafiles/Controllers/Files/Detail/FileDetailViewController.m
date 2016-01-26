//
//  FileDetailViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "FileDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>


@interface FileDetailViewController () <UIWebViewDelegate,UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;

@end

@implementation FileDetailViewController

- (void)dealloc
{
    self.viewLink = nil;
    self.webView.delegate = nil;
    self.object = nil;
    self.scrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL)isImageContentType:(NSString *)type
{
    NSArray * mimeTypes = @[@"image/jpeg",@"image/pjpeg",@"image/png",@"image/tiff"];
    if ([mimeTypes containsObject:type]) {
        return YES;
    }
    
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.alpha = 0;
    self.scrollView.alpha = 0;
    if (![self isImageContentType:[self.object objectForKey:@"ContentType"]])
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSURL *url = [NSURL URLWithString:[self.viewLink stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:50.0f];
        self.webView.delegate = self;
        [self.webView loadRequest:request];

    }
    else
    {
        self.scrollView.alpha = 1.0f;
        self.scrollView.backgroundColor = [UIColor blackColor];
        [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
        [[UINavigationBar appearance] setTranslucent:YES];
        self.scrollView.delegate = self;
        UIActivityIndicatorView * activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activity.center = self.view.center;

        [self.imageView addSubview:activity];
        [activity startAnimating];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.frame = self.scrollView.bounds;
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.viewLink] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
            [activity stopAnimating];
            [activity removeFromSuperview];
            [self setBarsHidden:YES animated:YES];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:nil];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self setBarsHidden:NO animated:YES];
}

- (void)orientationChanged:(NSNotification*)notification
{
    [self.webView reload];
}

#pragma mark Toolbars behavior

- (void)setBarsHidden:(BOOL) hidden animated:(BOOL)animated
{
//    [self.navigationController setNavigationBarHidden:hidden animated:animated];
//    [self.toolBar setHidden:hidden];
}

#pragma mark WebView

- (void)webViewDidFinishLoad:(nonnull UIWebView *)webView
{
    [UIView animateWithDuration:0.2f animations:^(){
        self.webView.alpha = 1.0f;
    }];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    CGSize contentSize = webView.scrollView.contentSize;
    CGSize viewSize = webView.bounds.size;
    
    float rw = viewSize.width / contentSize.width;
    
    webView.scrollView.minimumZoomScale = rw;
    webView.scrollView.maximumZoomScale = rw;
    webView.scrollView.zoomScale = rw;
}

- (void)webViewDidStartLoad:(nonnull UIWebView *)webView
{
    [UIView animateWithDuration:0.2f animations:^(){
        self.webView.alpha = 0;
    }];
}

- (void)webView:(nonnull UIWebView *)webView didFailLoadWithError:(nullable NSError *)error
{
    NSLog(@"%@",error);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}



#pragma mark scrollview

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}
@end

//
//  FileDetailViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "FileDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>


@interface FileDetailViewController () <UIWebViewDelegate>

@end

@implementation FileDetailViewController

- (void)dealloc
{
    self.viewLink = nil;
    self.webView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.alpha = 0;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    NSURL *url = [NSURL URLWithString:[self.viewLink stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:50.0f];
    self.webView.delegate = self;
    [self.webView loadRequest:request];
}

- (void)orientationChanged:(NSNotification*)notification
{
    [self.webView reload];
}

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

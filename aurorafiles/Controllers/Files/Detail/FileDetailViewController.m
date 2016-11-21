//
//  FileDetailViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "FileDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "API.h"
#import "Folder.h"
#import "UIImage+Aurora.h"
#import "Settings.h"
#import "ApiP8.h"
#import "StorageManager.h"
#import "MBProgressHUD.h"


@interface FileDetailViewController () <UIWebViewDelegate,UIScrollViewDelegate>{
    MBProgressHUD *hud;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) UITextField * folderName;
@property (weak, nonatomic) UIBarButtonItem * moreItem;
@property (weak, nonatomic) UITapGestureRecognizer * zoomOnDoubleTap;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareItem;

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

- (IBAction)shareFileAction:(id)sender
{
    NSURL *myWebsite = [NSURL URLWithString:self.viewLink];
    
    NSArray *objectsToShare = @[myWebsite];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.alpha = 0;
    
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeDeterminate;
    
    UITapGestureRecognizer * zoomOn = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomImageIn:)];
    zoomOn.numberOfTapsRequired = 2;
    zoomOn.numberOfTouchesRequired = 1;
    self.zoomOnDoubleTap = zoomOn;
    self.scrollView.alpha = 0;

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (self.object.isLink.boolValue)
    {
        self.viewLink = self.object.linkUrl;
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.object.linkUrl]];
        return;
        
    }
    
    if (self.isP8 && !self.viewLink) {
        [[ApiP8 filesModule] getFileView:self.object type:self.type withProgress:^(float progress) {
            dispatch_async(dispatch_get_main_queue(), ^(){
                hud.progress = progress;
                NSLog(@"%@ progress -> %f",self.object.name, progress);
            });
        } withCompletion:^(NSString *thumbnail) {
            NSURL *url = [NSURL URLWithString:[thumbnail stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:50.0f];
            self.webView.delegate = self;
            [self.webView loadRequest:request];
            [hud hideAnimated:YES];
        }];
        
    }else{
        NSURL *url = [NSURL URLWithString:[self.viewLink stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:50.0f];
        self.webView.delegate = self;
        [self.webView loadRequest:request];
        [hud hideAnimated:YES];
    }

    self.title = self.object.name;
    
    UIBarButtonItem * moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(moreItemAction:)];
    self.moreItem = moreItem;
    self.navigationItem.rightBarButtonItems = @[self.shareItem, self.moreItem];
    self.navigationController.navigationBar.hidden = NO;
}

//-(void)setViewLink:(NSString *)viewLink{
//    NSLog(@"link");
//}

- (IBAction)moreItemAction:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    
    [alert addAction:[self renameCurrentFileAction]];
    [alert addAction:[self deleteFolderAction]];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction*)renameCurrentFileAction
{
    UIAlertAction* renameFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Rename File", @"") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIAlertController * createFolder = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                             [createFolder addTextFieldWithConfigurationHandler:^(UITextField * textField) {
                                                                 Folder * file = self.object;
                                                                 
                                                                 
                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 textField.text = [file.name stringByDeletingPathExtension];
                                                                 self.folderName = textField;
                                                             }];
                                                             
                                                             UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                 [[StorageManager sharedManager]renameFile:self.object toNewName:self.folderName.text withCompletion:^(Folder *updatedFile) {
                                                                     if (updatedFile) {
                                                                         self.title = updatedFile.name;
                                                                         self.object = updatedFile;
                                                                     }
                                                                 }];
                                                             }];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                                                                 
                                                             }];
                                                             [createFolder addAction:defaultAction];
                                                             [createFolder addAction:cancelAction];
                                                             [self presentViewController:createFolder animated:YES completion:nil];
                                                         }];
    return renameFolder;
    
}


- (UIAlertAction*)deleteFolderAction
{
    UIAlertAction * deleteFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action){
        Folder * object = self.object;
        BOOL isCorporate = [object.type isEqualToString:@"corporate"];
        object.wasDeleted = @YES;
        if ([[Settings version] isEqualToString:@"P8"]) {
            [[ApiP8 filesModule]deleteFile:object isCorporate:isCorporate completion:^(BOOL succsess) {
                if (succsess) {
                    [self.object.managedObjectContext save:nil];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
        }else{
            [[API sharedInstance] deleteFile:object isCorporate:isCorporate completion:^(NSDictionary* handler) {
                [self.object.managedObjectContext save:nil];
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    }];
    
    return deleteFolder;
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

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.scrollView.alpha = 1.0f;
    self.imageView.image =  [UIImage assetImageForContentType:[self.object contentType]];
}

#pragma mark scrollview


- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = [[self viewForZoomingInScrollView:self.scrollView] frame].size.height / scale;
    zoomRect.size.width  = [[self viewForZoomingInScrollView:self.scrollView] frame].size.width  / scale;
    
    center = [[self viewForZoomingInScrollView:self.scrollView] convertPoint:center fromView:self.view];
    
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

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}
@end

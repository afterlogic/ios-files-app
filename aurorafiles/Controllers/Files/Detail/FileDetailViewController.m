//
//  FileDetailViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "FileDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <QuickLook/QuickLook.h>
#import "ApiP7.h"
#import "Folder.h"
#import "UIImage+Aurora.h"
#import "Settings.h"
#import "ApiP8.h"
#import "StorageManager.h"
#import "MBProgressHUD.h"
#import "UIApplication+openURL.h"


@interface FileDetailViewController () <UIWebViewDelegate,UIScrollViewDelegate, UIDocumentInteractionControllerDelegate,UITextFieldDelegate>{
    MBProgressHUD *hud;
    UIAlertAction * defaultAction;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) UITextField * folderName;
@property (weak, nonatomic) UIBarButtonItem * moreItem;
@property (weak, nonatomic) UITapGestureRecognizer * zoomOnDoubleTap;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareItem;
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractorVC;

@end

@implementation FileDetailViewController

- (void)dealloc
{
    self.viewLink = nil;
    self.webView.delegate = nil;
    self.object = nil;
    self.scrollView.delegate = nil;
    self.documentInteractorVC = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)shareFileAction:(id)sender
{
    NSURL *myWebsite = [NSURL URLWithString:self.viewLink];
    
    NSArray *objectsToShare = @[myWebsite];
    
    if ([self.object.isDownloaded boolValue]){
        self.documentInteractorVC = [UIDocumentInteractionController interactionControllerWithURL:[self.object localURL]];
        self.documentInteractorVC.delegate = self;
        [self.documentInteractorVC presentOptionsMenuFromBarButtonItem:self.shareItem animated:YES];
    }else{
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
        activityVC.popoverPresentationController.barButtonItem = self.shareItem;
        [self presentViewController:activityVC animated:YES completion:nil];
    }
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
//    if (self.object.isLink.boolValue)
//    {
//        self.viewLink = self.object.linkUrl;
//        [[UIApplication sharedApplication] openLink:[NSURL URLWithString:self.object.linkUrl]];
//        return;
//        
//    }
    
    NSURL *url = [NSURL URLWithString:self.viewLink];
    if (![self.object isZipArchive]){
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:50.0f];
        if (self.isP8){
            [request setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
        }
        self.webView.delegate = self;
        [self.webView loadRequest:request];
    }else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.scrollView.alpha = 1.0f;
        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.image =  [UIImage assetImageForContentType:[self.object contentType]];
        
    }
    
    [hud hideAnimated:YES];

    self.title = self.object.name;
    
    UIBarButtonItem * moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(moreItemAction:)];
    self.moreItem = moreItem;
    self.navigationItem.rightBarButtonItems = @[self.shareItem, self.moreItem];
    self.navigationController.navigationBar.hidden = NO;
}

- (IBAction)moreItemAction:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    
    [alert addAction:[self renameCurrentFileAction]];
    [alert addAction:[self deleteFolderAction]];
    [alert addAction:defaultAction];
    alert.popoverPresentationController.barButtonItem = self.moreItem;
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
                                                                 textField.text = file.name;
                                                                 textField.delegate = self;
                                                                 self.folderName = textField;
                                                             }];
                                                             void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
                                                                 [[StorageManager sharedManager] renameOperation:self.object withNewName:self.folderName.text withCompletion:^(Folder *updatedFile, NSError *error) {
                                                                     if(error){
                                                                         [[ErrorProvider instance]generatePopWithError:error controller:self customCancelAction:nil retryAction:actionBlock];
                                                                         return;
                                                                     }
                                                                     if (updatedFile) {
                                                                         self.title = updatedFile.name;
                                                                         self.object = updatedFile;
                                                                     }
                                                                 }];
                                                             };
                                                             
                                                             defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:actionBlock];
                                                             
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
      [[StorageManager sharedManager]deleteItem:object controller:self isCorporate:isCorporate completion:^(BOOL succsess, NSError *error) {
          if(error){
              return;
          }
          if (succsess) {
              [self.object.managedObjectContext save:nil];
              [self.navigationController popViewControllerAnimated:YES];
          }

      }];
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
#pragma mark - TextField Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    NSString *textFieldText = textField.text;
    NSString *fileExtension = textFieldText.pathExtension;
    NSRange fileExtensionRange = [textFieldText rangeOfString:fileExtension];
    if (fileExtensionRange.location == NSNotFound) {
        DDLogDebug(@"dot location is -> %lu",[textFieldText rangeOfString:@"."].location);
        if ([textFieldText containsString:@"."] && [textFieldText rangeOfString:@"."].location == 0){
            UITextPosition *startPosition = [textField positionFromPosition:[textField beginningOfDocument] offset:0];
            UITextPosition *endPosition = [textField positionFromPosition:startPosition offset:0];
            UITextRange *selectionRange = [textField textRangeFromPosition:startPosition toPosition:endPosition];
            [textField setSelectedTextRange:selectionRange];
            return;
        }else{
            [textField selectAll:nil];
            return;
        }
    }
    DDLogDebug(@"extension range for string %@ location -> %lu ,length -> %lu",textFieldText,(unsigned long)fileExtensionRange.location,(unsigned long)fileExtensionRange.length);
    UITextPosition *startPosition = [textField positionFromPosition:[textField beginningOfDocument] offset:0];
    UITextPosition *endPosition = [textField positionFromPosition:startPosition offset:textFieldText.length - fileExtensionRange.length-1];
    UITextRange *selectionRange = [textField textRangeFromPosition:startPosition toPosition:endPosition];
    [textField setSelectedTextRange:selectionRange];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString * currentTextFieldText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if(textField.text.length < currentTextFieldText.length){
        NSRange charRange = [currentTextFieldText rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:forbiddenCharactersForFileName]];
        if (charRange.location != NSNotFound) {
            return NO;
        }
    }
    BOOL  isActionEnabled =  currentTextFieldText.length>=minimalStringLengthFiles ? YES : NO;
    [defaultAction setEnabled:isActionEnabled] ;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    BOOL result = defaultAction.isEnabled;
    return result;
}

#pragma mark - Documents Interaction Delegate

-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return  self;
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
    if (error){
        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.image =  [UIImage assetImageForContentType:[self.object contentType]];
        [[ErrorProvider instance] generatePopWithError:error controller:nil];
    }

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

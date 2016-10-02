//
//  ActionViewController.m
//  aurorafilesaction
//
//  Created by Michael Akopyants on 07/06/16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

//#import <AVFoundation/AVFoundation.h>
#import "ActionViewController.h"
#import "EXFileGalleryCollectionViewController.h"
#import "EXPreviewFileGalleryCollectionViewController.h"
#import "CurrentFilePathViewController.h"
#import "TabBarWrapperViewController.h"
#import "PopUp/PopupViewController.h"
#import "Model/UploadedFile.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "Settings.h"
#import "EXConstants.h"
#import "NSString+URLEncode.h"

@interface ActionViewController ()<NSURLSessionTaskDelegate, GalleryDelegate, UploadFolderDelegate> {
    NSString *fileExtension;
    NSURL *mediaData;
    NSString * urlString;
    
    NSString *fileName;
    
    NSString *uploadFolderPath;
    NSString *uploadRootPath;
    
    unsigned long long uploadSize;
    
    UIAlertController * alertController;
    UIProgressView *pv;
    
    PopupViewController *allertPopUp;
    
    NSMutableArray <UploadedFile *> *filesForUpload;
    NSMutableArray <NSMutableURLRequest *> *requestsForUpload;
    
    
    int64_t totalBytesForAllFilesSend;
    CGFloat previewLocalHeight;
    UIViewController *currentModalView;
}


@property (strong, nonatomic) NSURL *movieURL;
@property (nonatomic, retain) AVPlayerViewController *playerViewController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (weak, nonatomic) IBOutlet UIView *userLoggedOutView;
@property (weak, nonatomic) EXFileGalleryCollectionViewController *galleryController;
@property (weak, nonatomic) EXPreviewFileGalleryCollectionViewController *previewController;
@property (weak, nonatomic) CurrentFilePathViewController *currentUploadPathView;
@property (weak, nonatomic) TabBarWrapperViewController *tabbarWrapController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeight;
@property (weak, nonatomic) IBOutlet UIView *galleryContainer;
@property (weak, nonatomic) IBOutlet UIView *previewContainer;
@property (weak, nonatomic) IBOutlet UIView *uploadPathContainer;



- (IBAction)uploadAction:(id)sender;

@end
//#import <AVKit/AVKit.h>

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![Settings token]) {
        self.uploadButton.enabled = NO;
        [self.uploadButton setTitle:@""];
        [self.userLoggedOutView setHidden:NO];
        [self hideContainers:YES];
    }else{
        [self hideContainers:NO];
        [self setupForUpload];
        [self setCurrentUploadFolder:@"" root:@"personal"];
        [self showUploadFolders];
    }
    
    
}

-(void)hideContainers:(BOOL) hide{
    self.galleryContainer.hidden = hide;
    self.previewContainer.hidden = hide;
    self.uploadPathContainer.hidden = hide;
}

-(void)setupForUpload{
    
    totalBytesForAllFilesSend = 0;
    [self searchFilesForUpload];
    
}

-(void)searchFilesForUpload{
    filesForUpload = [NSMutableArray new];
    NSArray *imputItems = self.extensionContext.inputItems;
    NSLog(@"input items is -> %@",imputItems);
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            //image
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
//                __weak UIImageView *imageView = self.imageView;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id image, NSError *error) {
                    if(image) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if([image isKindOfClass:[NSURL class]]) {
                                fileExtension = [[[(NSURL *)image absoluteString] componentsSeparatedByString:@"."]lastObject];
                                mediaData = image;
//                                [imageView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:image]]];
//                                imageView.alpha = 0.0f;
                                
                                UploadedFile *file = [UploadedFile new];
                                file.path = mediaData;
                                file.extension = fileExtension;
                                file.type = (NSString *)kUTTypeImage;
                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
                                
                                [filesForUpload addObject:file];
                            }
                        }];
                    }
                }];
            }
            
            //video
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
                __weak AVPlayerViewController *player = self.playerViewController;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(id videoItem, NSError *error) {
                    if(videoItem) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if ([videoItem isKindOfClass:[NSURL class]]) {
                                fileExtension = [[[(NSURL *)videoItem absoluteString] componentsSeparatedByString:@"."]lastObject];
                                mediaData = videoItem;
                                player.player  = [AVPlayer playerWithURL:(NSURL *)videoItem];
                                player.view.alpha = 0.0f;
                                
                                UploadedFile *file = [UploadedFile new];
                                file.path = mediaData;
                                file.extension = fileExtension;
                                file.type = (NSString *)kUTTypeMovie;
                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
                                
                                [filesForUpload addObject:file];
                            }
                        }];
                    }
                }];
            }
            
            //internet shortcut
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(id fileURLItem, NSError *error) {
                    if(fileURLItem) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if ([fileURLItem isKindOfClass:[NSURL class]]) {
                                fileExtension = @"url";
                                NSString *tmpFileName = [NSString stringWithFormat:@"InternetShortcut_%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]];
                                mediaData = [self createInternetShortcutFile:tmpFileName ext:fileExtension link:fileURLItem];
                                
                                UploadedFile *file = [UploadedFile new];
                                file.path = mediaData;
                                file.extension = fileExtension;
                                file.type = (NSString *)kUTTypeURL;
                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
                                
                                [filesForUpload addObject:file];
                            }
                        }];
                    }
                }];
            }
            
        }
        
    }
    
}

-(void)viewWillAppear:(BOOL)animated{
    self.galleryController.items = filesForUpload.copy;
    self.previewController.items = filesForUpload.copy;
    self.galleryController.delegate = self;
    [self.currentUploadPathView.openFileButton addTarget:self action:@selector(showUploadFolders) forControlEvents:UIControlEventTouchUpInside];
//    [self.currentUploadPathView setUploadPath:uploadFolderPath];
    [self generatePath:uploadFolderPath root:uploadRootPath];
    if([NSObject orientation] == InterfaceOrientationTypePortrait){
        [self setPreviewGalleryHeightForOrientation:InterfaceOrientationTypePortrait];
    }else{
         [self setPreviewGalleryHeightForOrientation:InterfaceOrientationTypeLandscape];
    }
    
}

- (void)setCurrentUploadFolder:(NSString *)folderPath root:(NSString *)root{
    [self generatePath:folderPath root:root];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)generatePath:(NSString *)folderPath root:(NSString *)root{
    uploadFolderPath = folderPath;
    uploadRootPath = root;
    NSString *targetPath = [folderPath componentsSeparatedByString:@"/"].lastObject;
    [self.currentUploadPathView setUploadPath:[NSString stringWithFormat:@"%@ : %@",root,targetPath]];
}



-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        [self setPreviewGalleryHeightForOrientation:toInterfaceOrientation];
    }else{
        [self setPreviewGalleryHeightForOrientation:toInterfaceOrientation];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showUploadFolders{
    [self performSegueWithIdentifier:@"push_files" sender:self];
}

- (IBAction)done
{
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

#pragma mark - Upload

- (IBAction)uploadAction:(id)sender
{
    
    urlString = @"";
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    requestsForUpload = [NSMutableArray new];
    
    for (UploadedFile *file in filesForUpload){
        if ([file.type isEqualToString:(NSString *)kUTTypeURL]) {
            
            file.name = [NSString stringWithFormat:@"InternetShortcut%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],file.extension];
        }else{
            file.name = [[[file.path absoluteString] componentsSeparatedByString:@"/"]lastObject];
        }
        urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[defaults valueForKey:@"mail_domain"],[[NSString stringWithFormat:@"%@%@",uploadRootPath,uploadFolderPath] urlEncodeUsingEncoding:NSUTF8StringEncoding],file.name];
        file.request = [self generateRequestWithUrl:[NSURL URLWithString:urlString]data:file.path];
        
        uploadSize += file.size;
    }
    
    allertPopUp = [[PopupViewController alloc]initProgressAllertWithTitle:@"" message:NSLocalizedString(@"Uploading..", @"")  fileName:fileName fileSize:[NSString stringWithFormat:@"%llu",uploadSize] disagreeText:NSLocalizedString(@"Cancel", @"") disagreeBlock:^{
        [self done];
    } parrentView:self];
    
    [self startUploadingForFiles:filesForUpload];
}

-(void)startUploadingForFiles:(NSArray *)files{
    
    UploadedFile *currentFile = files.firstObject;
    if (allertPopUp.isShown) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [allertPopUp setCurrentFileName:currentFile.name];
        });
    }
    [self uploadFile:currentFile];
}

-(NSMutableURLRequest *)generateRequestWithUrl:(NSURL *)url data:(NSURL *)data
{
    
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"PUT"];
    
    NSString *authToken = [defaults valueForKey:@"auth_token"];
    [request setValue:authToken forHTTPHeaderField:@"Auth-Token"];

    [request setHTTPBodyStream:[[NSInputStream alloc]initWithURL:data]];
    
    [request setValue:uploadRootPath forHTTPHeaderField:@"Type"];
    [request setValue:[NSString stringWithFormat:@"{\"Type\":\"%@\"}",uploadRootPath]  forHTTPHeaderField:@"AdditionalData"];
    
   
    return request;
}


-(void)uploadFile:(UploadedFile *) file{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    
    if (!allertPopUp.isShown) {
        [allertPopUp showPopup];
    }

    [self requestLog:file.request];
    NSURLSessionDataTask * task = [session dataTaskWithRequest:file.request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            NSError * error = nil;
            
            id json = nil;
            if (data)
            {
                json =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            }
            
            if (![json isKindOfClass:[NSDictionary class]])
            {
                error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }
            
            if (error)
            {
                if (filesForUpload.count == 0) {
                    [allertPopUp closeViewWithComplition:^{
                        PopupViewController* errorPopUp = [[PopupViewController alloc] initPopUpWithOneButtonWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Operation can't be completed", @"") agreeText:NSLocalizedString(@"OK", @"") agreeBlock:^{
                            [self done];
                        } parrentView:self];
                        [errorPopUp showPopup];
                    }];
                    return ;
                }else{
                    
                }

            }
            
            if (filesForUpload.count == 1) {
                [allertPopUp closeViewWithComplition:^{
                    PopupViewController* congratPopUp = [[PopupViewController alloc]initPopUpWithOneButtonWithTitle:NSLocalizedString(@"Great!", @"") message:NSLocalizedString(@"File succesfully uploaded!", @"") agreeText:NSLocalizedString(@"OK", @"") agreeBlock:^{
                          [self done];
                    } parrentView:self];
                    [congratPopUp showPopup];
                }];
            }else{
                [filesForUpload removeObject:file];
                [self startUploadingForFiles:filesForUpload];
            }
            
        });
    }];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{

    dispatch_async(dispatch_get_main_queue(), ^(){
        totalBytesForAllFilesSend +=bytesSent;
        [allertPopUp setProgressWihtCurrentBytes:totalBytesForAllFilesSend totalBytesExpectedToSend:uploadSize];
    });

    
}



-(void)requestLog:(NSURLRequest *)request {
    NSLog(@"Method: %@", request.HTTPMethod);
    NSLog(@"URL: %@", request.URL.absoluteString);
    NSLog(@"Body: %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    NSLog(@"Head: %@",request.allHTTPHeaderFields);
}

-(NSURL *)createInternetShortcutFile:(NSString *)name ext:(NSString *)extension link:(NSURL *)link{
    NSError *error;
//    NSArray *stringParams = [NSArray new];
//    stringParams = @[@"[InternetShortcut]",[NSString stringWithFormat:@"URL=%@",link.absoluteString]];
   
    NSString *stringToWrite = [@[@"[InternetShortcut]",[NSString stringWithFormat:@"URL=%@",link.absoluteString]] componentsJoinedByString:@"\n"];

    NSString *shortcutName = [NSString stringWithFormat:@"%@.%@",name,extension];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:shortcutName];
    [stringToWrite writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    NSURL *resultPath = [NSURL fileURLWithPath:filePath];
    NSLog(@"%@", resultPath);
    return resultPath;
}

#pragma mark - Preview

-(void)setPreviewGalleryHeightForOrientation:(NSInteger) orientation{
    previewLocalHeight = previewHeightConst;
    
    if(UIInterfaceOrientationIsPortrait(orientation)){
        
        CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
        CGFloat height = 0;
        if([NSObject orientation] == InterfaceOrientationTypePortrait){
            height = iOSDeviceScreenSize.height;
        }else{
            height = iOSDeviceScreenSize.width;
        }
        
        if(height > 568)
        {
            previewLocalHeight = previewHeightConst;
        }
        
        if (height <= 568){
            previewLocalHeight = previewHeightConst * scaleFactor1Devider;
        }
        
        if (filesForUpload.count > 5) {
            previewLocalHeight = previewLocalHeight * 2 + previewLineHeight;
        }else{
            previewLocalHeight += previewLineHeight;
        }
        
    }
    [_previewHeight setConstant:previewLocalHeight];
}

- (void)selectGalleryItem:(UploadedFile *)item{
    [self.previewController highlightItem:item];
}



#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"gallery_embed"]) {
        self.galleryController = (EXFileGalleryCollectionViewController *)[segue destinationViewController];
    }
    if ([segue.identifier isEqualToString:@"preview_embed"]){
        self.previewController = (EXPreviewFileGalleryCollectionViewController *)[segue destinationViewController];
    }
    
    if ([segue.identifier isEqualToString:@"filePath_embed"]){
        self.currentUploadPathView = (CurrentFilePathViewController *)[segue destinationViewController];
    }
    
    if ([segue.identifier isEqualToString:@"push_files"]){
        TabBarWrapperViewController *vc = (TabBarWrapperViewController *)[segue destinationViewController];
        vc.delegate = self;
        self.tabbarWrapController = vc;
    }
}


@end

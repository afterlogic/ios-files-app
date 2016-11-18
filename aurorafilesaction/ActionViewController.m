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
#import "Model/UploadedFile.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "Settings.h"
#import "EXConstants.h"
#import "NSString+URLEncode.h"
#import <BugfenderSDK/BugfenderSDK.h>
#import "MLNetworkLogger.h"
#import "MBProgressHUD.h"
#import "NSObject+PerformSelectorWithCallback.h"
#import "NSString+transferedValues.h"
#import "AFNetworking.h"
#import "AFNetworkActivityLogger.h"
#import "SessionProvider.h"
#import "StorageManager.h"
//#import

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
    
    MBProgressHUD *hud;
    
    NSMutableArray <NSMutableURLRequest *> *requestsForUpload;
    
    
    int64_t totalBytesForAllFilesSend;
    CGFloat previewLocalHeight;
    UIViewController *currentModalView;
    BOOL uploadStart;
    
    AFHTTPRequestOperationManager *manager;
}


@property (strong, nonatomic) NSURL *movieURL;
@property (strong, nonatomic) NSMutableArray <UploadedFile *> *filesForUpload;
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
-(void)loadView{
    [super loadView];
    [Bugfender enableAllWithToken:@"XjOPlmw9neXecfebLqUwiSfKOCLxwCHT"];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    [[StorageManager sharedManager]initCoreData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    BFLog(@"EXTENSION STARTED");
    self.uploadPathContainer.hidden = YES;
    [self setCurrentUploadFolder:@"" root:@""];
    MBProgressHUD * connectionHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    connectionHud.mode = MBProgressHUDModeIndeterminate;
    connectionHud.label.text = NSLocalizedString(@"Check connection...", @"");
    
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString *scheme = [url scheme];
    if (scheme) {
        [self setupInterfaceForP8:[[Settings version]isEqualToString:@"P8"]];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [connectionHud hideAnimated:YES];
        });
    }else{
        [[SessionProvider sharedManager]checkSSLConnection:^(NSString *domain) {
            dispatch_async(dispatch_get_main_queue(), ^(){
                [connectionHud hideAnimated:YES];
            });
            if(domain && domain.length > 0){
                [Settings setDomain:domain];
                [self setupInterfaceForP8:[[Settings version]isEqualToString:@"P8"]];
            }else{
                [self hideLogoutView:NO];
                [self hideContainers:YES];
            }
        }];
    }
}

-(void)setupInterfaceForP8:(BOOL)isP8 {
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString *scheme = [url scheme];
    if (isP8){
        if (![Settings authToken] || !scheme) {
            [self hideLogoutView:NO];
            [self hideContainers:YES];
        }else{
            [[StorageManager sharedManager]getLastUsedFolderWithHandler:^(NSDictionary *result) {
                [self hideContainers:NO];
                [self setupForUpload];
                if (result) {
                    [self setCurrentUploadFolder:result[@"FullPath"] root:result[@"Type"]];
                }else{
                    [self setCurrentUploadFolder:@"" root:@"personal"];
                    [self showUploadFolders];
                }
            }];

        }
    }else{
        if (![Settings token] || !scheme) {
            [self hideLogoutView:NO];
            [self hideContainers:YES];
        }else{
            [self hideContainers:NO];
            [self setupForUpload];
            [[StorageManager sharedManager]getLastUsedFolderWithHandler:^(NSDictionary *result) {
//                dispatch_async(dispatch_get_main_queue(), ^(){
                    if (result) {
                        [self setCurrentUploadFolder:result[@"FullPath"] root:result[@"Type"]];
                    }else{
                        [self setCurrentUploadFolder:@"" root:@"personal"];
                        [self showUploadFolders];
                    }
//                });
            }];
        }
    }
    
}

-(void)hideContainers:(BOOL) hide{
    self.galleryContainer.hidden = hide;
    self.previewContainer.hidden = hide;
    self.uploadPathContainer.hidden = hide;
}

-(void)hideLogoutView:(BOOL) hide{
    self.uploadButton.enabled = !hide;
    [self.uploadButton setTitle:@""];
    [self.userLoggedOutView setHidden:hide];
}

-(void)setupForUpload{
    manager = [AFHTTPRequestOperationManager manager];
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    manager.securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy.validatesDomainName = NO;
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    totalBytesForAllFilesSend = 0;
    uploadStart = NO;
    [self searchFilesForUpload];
    
}

-(void)searchFilesForUpload{
    self.filesForUpload = [NSMutableArray new];
    NSArray *imputItems = self.extensionContext.inputItems;
    BFLog(@"input items is -> %@",imputItems);
    for (NSExtensionItem *item in imputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            //image
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id image, NSError *error) {
                    if(image) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if([image isKindOfClass:[NSURL class]]) {
                                fileExtension = [[[(NSURL *)image absoluteString] componentsSeparatedByString:@"."]lastObject];
                                mediaData = image;
                                UploadedFile *file = [UploadedFile new];
                                file.path = mediaData;
                                file.extension = fileExtension;
                                file.type = (NSString *)kUTTypeImage;
                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
                                [self.filesForUpload addObject:file];
                            }
                            if ([image isKindOfClass:[UIImage class]]){
                                
//                                fileExtension = [[[(NSURL *)image absoluteString] componentsSeparatedByString:@"."]lastObject];
//                                mediaData = image;
//                                UploadedFile *file = [UploadedFile new];
//                                file.path = mediaData;
//                                file.extension = fileExtension;
//                                file.type = (NSString *)kUTTypeImage;
//                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
//                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
//                                [self.filesForUpload addObject:file];
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
                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
                                [self.filesForUpload addObject:file];
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
                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
                                [self.filesForUpload addObject:file];
                            }
                        }];
                    }
                }];
            }
            
        }
        
    }
    
}

-(void)viewWillAppear:(BOOL)animated{
    self.galleryController.items = self.filesForUpload.copy;
    self.previewController.items = self.filesForUpload.copy;
    self.galleryController.delegate = self;
    [self.currentUploadPathView.openFileButton addTarget:self action:@selector(showUploadFolders) forControlEvents:UIControlEventTouchUpInside];
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
    BFLog(@"EXTENSION END WORK");
    [manager.operationQueue cancelAllOperations];
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

#pragma mark - Upload

- (IBAction)uploadAction:(id)sender
{
    urlString = @"";
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    requestsForUpload = [NSMutableArray new];
    
    for (UploadedFile *file in self.filesForUpload){
        if ([file.type isEqualToString:(NSString *)kUTTypeURL]) {
            file.name = [NSString stringWithFormat:@"InternetShortcut%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],file.extension];
        }else{
            file.name = [[[file.path absoluteString] componentsSeparatedByString:@"/"]lastObject];
        }
        if ([[Settings version]isEqualToString:@"P8"]) {
            file.request = [self generateP8RequestWithFile:file.path mime:file.MIMEType toFolderPath:uploadFolderPath withName:file.name rootPath:uploadRootPath];
        }else{
            NSURL * url = [NSURL URLWithString:[Settings domain]];
            NSString * scheme = [url scheme];
            urlString = [NSString stringWithFormat:@"%@%@/index.php?Upload/File/%@/%@",scheme ? @"" : @"https://",[defaults valueForKey:@"mail_domain"],[[NSString stringWithFormat:@"%@%@",uploadRootPath,uploadFolderPath] urlEncodeUsingEncoding:NSUTF8StringEncoding],file.name];
            file.request = [self generateRequestWithUrl:[NSURL URLWithString:urlString]data:file.path];
        }
        
        if(!uploadStart){
            uploadSize += file.size;
        }
    }
    self.uploadButton.enabled = NO;
    [self startUploadingForFiles:self.filesForUpload];
}

-(void)startUploadingForFiles:(NSArray *)files{
    
    UploadedFile *currentFile = files.firstObject;
    fileName = currentFile.name;
    if (uploadStart) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            fileName = currentFile.name;
        });
    }
//    if ([[Settings version]isEqualToString:@"P8"]) {
//        [self uploadP8File:currentFile];
//    }else{
        [self uploadFile:currentFile];
//    }
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

-(NSMutableURLRequest *)generateP8RequestWithFile:(NSURL *)file mime:(NSString *)mime toFolderPath:(NSString *)path withName:(NSString *)name rootPath:(NSString *)rootPath
{
    
    NSString *storageType = [NSString stringWithString:rootPath];
    NSString *pathTmp = [NSString stringWithFormat:@"%@",path.length ? [NSString stringWithFormat:@"%@",path] : @""];
    NSString *Link = [NSString stringWithFormat:@"http://cloudtest.afterlogic.com/?/upload/files/%@%@/%@",storageType,pathTmp,name];
    NSURL *testUrl = [[NSURL alloc]initWithString:[Link stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSDictionary *headers = @{ @"auth-token": [Settings authToken],
                               @"cache-control": @"no-cache"};
    
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:testUrl];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithURL:file]];
    
    return request;
}


-(void)uploadFile:(UploadedFile *) file{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    uploadStart = YES;
    if (!hud) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        [hud showAnimated:YES];
    }

    [self requestLog:file.request];
    __weak ActionViewController * weakSelf = self;
    NSURLSessionDataTask * task = [session dataTaskWithRequest:file.request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError * error = nil;
            NSString *result;
            BOOL handlResult = false;
            ActionViewController *strongSelf = weakSelf;
            id json = nil;
            if (data)
            {
                json =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            }
            
            if (![json isKindOfClass:[NSDictionary class]])
            {
                result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                handlResult = [result isEqualToString:@"true"];
                if (!handlResult)
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                }else{
                    error = nil;
                }
            }
            
            if (error)
            {
                if (self.filesForUpload.count == 1) {
                    hud.mode = MBProgressHUDModeCustomView;
                    hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"error"]];
                    hud.detailsLabel.text = @"";
                    hud.label.text = NSLocalizedString(@"Files uploaded with some errors...", @"");
                    [hud hideAnimated:YES afterDelay:0.7f];
//                    return ;
                }else{
                    [strongSelf.filesForUpload removeObject:file];
                    [strongSelf uploadAction:self];
                }

            }else{
                if (self.filesForUpload.count == 1) {
                    hud.mode = MBProgressHUDModeCustomView;
                    hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"success"]];
                    hud.detailsLabel.text = @"";
                    hud.label.text = NSLocalizedString(@"Files succesfully uploaded!", @"");
                    [strongSelf performSelector:@selector(hideHud) withObject:nil afterDelay:0.7];
                    
                }else{
                    [strongSelf.filesForUpload removeObject:file];
                    [strongSelf uploadAction:self];
                }
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
        float progress = (float)totalBytesForAllFilesSend / (float)uploadSize;
        hud.progress = progress;
        NSString *uploadStatus = [NSString stringWithFormat:@"%@ %@",[NSString transformedValue:[NSNumber numberWithLongLong:totalBytesForAllFilesSend]],[NSString transformedValue:[NSNumber numberWithLongLong:uploadSize]]];
        hud.detailsLabel.text = uploadStatus;
        NSLog(@"fileName is -> %@",fileName);
        hud.label.text = fileName;
    });

    
}



-(void)requestLog:(NSURLRequest *)request {
    BFLog(@"Method: %@", request.HTTPMethod);
    BFLog(@"URL: %@", request.URL.absoluteString);
    BFLog(@"Body: %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    BFLog(@"Head: %@",request.allHTTPHeaderFields);
}

-(NSURL *)createInternetShortcutFile:(NSString *)name ext:(NSString *)extension link:(NSURL *)link{
    NSError *error;
    
    NSString *stringToWrite = [@[@"[InternetShortcut]",[NSString stringWithFormat:@"URL=%@",link.absoluteString]] componentsJoinedByString:@"\n"];

    NSString *shortcutName = [NSString stringWithFormat:@"%@.%@",name,extension];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:shortcutName];
    [stringToWrite writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    NSURL *resultPath = [NSURL fileURLWithPath:filePath];
    BFLog(@"%@", resultPath);
    return resultPath;
}

#pragma mark - HUD

- (void)hideHud{
    [hud hideAnimated:YES];
    [self done];
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
        
        if (self.filesForUpload.count > 5) {
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

#pragma maerk - Helpers
- (NSString*)mimeTypeForFileAtPath: (NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return ( __bridge NSString *)mimeType;
}

@end

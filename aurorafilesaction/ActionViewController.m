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
#import "NSObject+PerformSelectorWithCallback.h"
#import "NSString+transferedValues.h"
#import "AFNetworking.h"
#import "AFNetworkActivityLogger.h"
#import "SessionProvider.h"
#import "StorageManager.h"
#import "DataBaseProvider.h"
#import "FileOperationsProvider.h"

#import "AuroraHUD.h"

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
    
    AuroraHUD *hud;
    
    NSMutableArray <NSMutableURLRequest *> *requestsForUpload;
    
    
    int64_t totalBytesForAllFilesSend;
    CGFloat previewLocalHeight;
    UIViewController *currentModalView;
    BOOL uploadStart;
    
    AFHTTPRequestOperationManager *manager;
    
    NSMutableArray *localSaveFileLinks;
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
    
    [[DataBaseProvider sharedProvider] setupCoreDataStack];
    [[StorageManager sharedManager]setupDBProvider:[DataBaseProvider sharedProvider]];
    [[StorageManager sharedManager]setupFileOperationsProvider:[FileOperationsProvider sharedProvider]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [ErrorProvider instance].currentViewController = self;
    
    BFLog(@"EXTENSION STARTED");
    self.uploadPathContainer.hidden = YES;
    [self setCurrentUploadFolder:@"" root:@""];
    
    AuroraHUD * connectionHud = [AuroraHUD checkConnectionHUD:self];
//    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString *scheme = [Settings domainScheme];
    if (scheme) {
        [self setupInterfaceForP8:[[Settings version]isEqualToString:@"P8"]];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [connectionHud hideHUD];
        });
    }else{
        [[SessionProvider sharedManager]checkSSLConnection:^(NSString *domain) {
            dispatch_async(dispatch_get_main_queue(), ^(){
                [connectionHud hideHUD];
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
//    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString *scheme = [Settings domainScheme];
    NSString *authToken = [Settings authToken];
    NSString *token = [Settings token];
    
    AuroraHUD *folderHud = [AuroraHUD checkFileExistanceHUD:self];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if (isP8){
        if (authToken.length==0 || !scheme) {
            [self hideLogoutView:NO];
            [self hideContainers:YES];
            dispatch_async(dispatch_get_main_queue(), ^(){
                [folderHud hideHUD];
            });
        }else{
            [self hideContainers:NO];
            [self setupForUpload];
//            [NSTimer scheduledTimerWithTimeInterval:5.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self getLastUsedFolder:folderHud];
//            }];
            
        }
    }else{
        if (!token || !scheme) {
            [self hideLogoutView:NO];
            [self hideContainers:YES];
        }else{
            [self hideContainers:NO];
            [self setupForUpload];
//            [NSTimer scheduledTimerWithTimeInterval:5.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self getLastUsedFolder:folderHud];
//            }];
        }
    }
    
}

- (void)getLastUsedFolder:(AuroraHUD *)folderHud{
    [[StorageManager sharedManager]getLastUsedFolderWithHandler:^(NSDictionary *result, NSError *error) {
        if (result) {
            dispatch_async(dispatch_get_main_queue(), ^(){
                [folderHud hideHUD];
            });
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [self setCurrentUploadFolder:result[@"FullPath"] root:result[@"Type"]];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^(){
                [folderHud hideHUD];
            });
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [self setCurrentUploadFolder:@"" root:@"personal"];
            [self showUploadFolders];
        }
    }];
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
    localSaveFileLinks = [[NSMutableArray alloc]init];
    [self searchFilesForUpload];
}

-(void)searchFilesForUpload{
    self.filesForUpload = [NSMutableArray new];
    NSArray *imputItems = self.extensionContext.inputItems;
    BFLog(@"input items is -> %@",imputItems);
    for (NSExtensionItem *item in imputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            mediaData = nil;
            
//TODO:Раскомментировать, если понадобятся картинки и видео.
//            //image
//            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
//                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id image, NSError *error) {
//                    if(image) {
//                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                            if([image isKindOfClass:[NSURL class]]) {
//                                fileExtension = [[[(NSURL *)image absoluteString] componentsSeparatedByString:@"."]lastObject];
//                                mediaData = image;
//                                UploadedFile *file = [UploadedFile new];
//                                file.path = mediaData;
//                                file.extension = fileExtension;
//                                file.type = (NSString *)kUTTypeImage;
//                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
//                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
//                                [self.filesForUpload addObject:file];
//                                return ;
//                            }
//                            if ([image isKindOfClass:[UIImage class]]){
////                                [NSFileManager defaultManager];
////                                thumbnail = [json valueForKey:@"Result"];
//                                NSData *data = [[NSData alloc]initWithData:UIImageJPEGRepresentation(image, 10.0)];
//                                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//                                
//                                NSString *uploadFileFolderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/UploadedFiles"];
//                                NSError *error = [NSError new];
//                                if (![[NSFileManager defaultManager] fileExistsAtPath:uploadFileFolderPath]){
//                                    [[NSFileManager defaultManager] createDirectoryAtPath:uploadFileFolderPath withIntermediateDirectories:NO attributes:nil error:&error];
//                                } //Create folder
//                                
//                                
//                                NSString *name = [NSString stringWithFormat:@"upldImage_%@.jpg",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]];
//                                NSString* path = [uploadFileFolderPath stringByAppendingPathComponent:name];
//                                [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
////                                [localSaveFileLinks addObject:path];
//                                
//                                fileExtension = [[name componentsSeparatedByString:@"."]lastObject];
//                                mediaData = [NSURL URLWithString:path];
//                                UploadedFile *file = [UploadedFile new];
//                                file.path = mediaData;
//                                file.extension = fileExtension;
//                                file.type = (NSString *)kUTTypeImage;
//                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
//                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
//                                file.savedLocal = YES;
//                                
////                                UIImage *resavedImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:mediaData.absoluteString]];
//                                
//                                [self.filesForUpload addObject:file];
//                                return ;
//                            }
//                            
//                            if([image isKindOfClass:[NSData class]]){
//                                
////                                UIImage *currentImage =  [UIImage imageWithData:image];
////                                DDLogDebug(@"image is -> %@",currentImage);
//                                
//                                NSData *data = image;
//                                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//                                
//                                NSString *uploadFileFolderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/UploadedFiles"];
//                                NSError *error = [NSError new];
//                                if (![[NSFileManager defaultManager] fileExistsAtPath:uploadFileFolderPath]){
//                                    [[NSFileManager defaultManager] createDirectoryAtPath:uploadFileFolderPath withIntermediateDirectories:NO attributes:nil error:&error];
//                                } //Create folder
//                                
//                                
//                                NSString *name = [NSString stringWithFormat:@"upldImage_%@.jpg",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]];
//                                NSString* path = [uploadFileFolderPath stringByAppendingPathComponent:name];
//                                [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
//                                //                                [localSaveFileLinks addObject:path];
//                                
//                                fileExtension = [[name componentsSeparatedByString:@"."]lastObject];
//                                mediaData = [[NSURL alloc ]initWithString:path];
//                                UploadedFile *file = [UploadedFile new];
//                                file.path = mediaData;
//                                file.extension = fileExtension;
//                                file.type = (NSString *)kUTTypeImage;
//                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
//                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
//                                file.savedLocal = YES;
//                                [self.filesForUpload addObject:file];
//                                return ;
//                            }
//                        }];
//                    }
//                }];
//            }
//            //video
//            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
//                __weak AVPlayerViewController *player = self.playerViewController;
//                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(id videoItem, NSError *error) {
//                    if(videoItem) {
//                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                            if ([videoItem isKindOfClass:[NSURL class]]) {
//                                fileExtension = [[[(NSURL *)videoItem absoluteString] componentsSeparatedByString:@"."]lastObject];
//                                mediaData = videoItem;
//                                player.player  = [AVPlayer playerWithURL:(NSURL *)videoItem];
//                                player.view.alpha = 0.0f;
//                                
//                                UploadedFile *file = [UploadedFile new];
//                                file.path = mediaData;
//                                file.extension = fileExtension;
//                                file.type = (NSString *)kUTTypeMovie;
//                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
//                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
//                                [self.filesForUpload addObject:file];
//                            }
//                        }];
//                    }
//                }];
//            }
            
            //internet shortcut from webPage
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(id fileURLItem, NSError *error) {
                    if(fileURLItem) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if ([fileURLItem isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *pageInfo = [fileURLItem objectForKey:NSExtensionJavaScriptPreprocessingResultsKey];
                                NSURL *pageLink = [NSURL URLWithString:[pageInfo objectForKey:@"link"]];
                                NSString *webPageTitle = [pageInfo objectForKey:@"title"];
//                                DDLogDebug(@"%@",webPageTitle);
                                fileExtension = @"url";
                                mediaData = [self createInternetShortcutFile:webPageTitle ext:fileExtension link:pageLink];
                                UploadedFile *file = [UploadedFile new];
                                file.path = mediaData;
                                file.extension = fileExtension;
                                file.type = (NSString *)kUTTypeURL;
                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
                                file.name = webPageTitle.copy;
                                file.webPageLink = pageLink;
                                [self.filesForUpload addObject:file];
                            }
                        }];
                    }
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(id fileURLItem, NSError *error) {
                    if(fileURLItem) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if ([fileURLItem isKindOfClass:[NSURL class]]) {
                                fileExtension = @"url";
                                NSMutableArray *urlParts = [[(NSURL *) fileURLItem absoluteString] componentsSeparatedByString:@"/"].mutableCopy;
                                NSMutableArray *urlPartsTmp = urlParts.mutableCopy;
                                for (NSString *part in urlPartsTmp) {
                                    if ([part isEqualToString:@""]) {
                                        [urlParts removeObject:part];
                                    }
                                }
                                NSString *tmpFileName = [urlParts lastObject];
                                mediaData = [self createInternetShortcutFile:tmpFileName ext:fileExtension link:fileURLItem];
                                UploadedFile *file = [UploadedFile new];
                                file.path = mediaData;
                                file.extension = fileExtension;
                                file.type = (NSString *)kUTTypeURL;
                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
                                file.name = tmpFileName.copy;
                                file.webPageLink = fileURLItem;
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
- (IBAction)logoutCloseButton:(id)sender {
    [self done];
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
//    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    requestsForUpload = [NSMutableArray new];
    
    for (UploadedFile *file in self.filesForUpload){
        if ([file.type isEqualToString:(NSString *)kUTTypeURL]) {
            NSString *lastPathComponent = [file.path lastPathComponent];
//            file.name = [NSString stringWithFormat:@"InternetShortcut%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],file.extension];
            file.name = lastPathComponent;
        }else{
            file.name = [[[file.path absoluteString] componentsSeparatedByString:@"/"]lastObject];
        }
        if ([[Settings version]isEqualToString:@"P8"]) {
            file.request = [self generateP8RequestWithFile:file.path mime:file.MIMEType toFolderPath:uploadFolderPath withName:file.name rootPath:uploadRootPath savedLocal:file.savedLocal];
        }else{
            NSURL * url = [NSURL URLWithString:[Settings domain]];
            NSString * scheme = [url scheme];
            urlString = [NSString stringWithFormat:@"%@%@/index.php?Upload/File/%@/%@",scheme ? @"" : @"https://",[Settings domain],[[NSString stringWithFormat:@"%@%@",uploadRootPath,uploadFolderPath] urlEncodeUsingEncoding:NSUTF8StringEncoding],file.name];
            file.request = [self generateRequestWithUrl:urlString data:file.path savedLocal:file.savedLocal];
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
    [self uploadFile:currentFile];
}

-(NSMutableURLRequest *)generateRequestWithUrl:(NSString *)linkString data:(NSURL *)data savedLocal:(BOOL) isLocal
{
    
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    NSURL *url = [NSURL URLWithString:[linkString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"PUT"];
    
    NSString *authToken = [defaults valueForKey:@"auth_token"];
    [request setValue:authToken forHTTPHeaderField:@"Auth-Token"];

    [request setHTTPBodyStream:isLocal ? [NSInputStream inputStreamWithFileAtPath:data.absoluteString] :[[NSInputStream alloc]initWithURL:data]];
    
//    [request setValue:uploadRootPath forHTTPHeaderField:@"Type"];
//    [request setValue:[NSString stringWithFormat:@"{\"Type\":\"%@\"}",uploadRootPath]  forHTTPHeaderField:@"AdditionalData"];
    
   
    return request;
}

-(NSMutableURLRequest *)generateP8RequestWithFile:(NSURL *)file mime:(NSString *)mime toFolderPath:(NSString *)path withName:(NSString *)name rootPath:(NSString *)rootPath savedLocal:(BOOL) isLocal
{
    
    NSString *storageType = [NSString stringWithString:rootPath];
    NSString *pathTmp = [NSString stringWithFormat:@"%@",path.length ? [NSString stringWithFormat:@"%@",path] : @""];
    NSString *Link = [NSString stringWithFormat:@"%@%@/?/upload/files/%@%@/%@",[Settings domainScheme],[Settings domain],storageType,pathTmp,name];
    NSURL *testUrl = [[NSURL alloc]initWithString:[Link stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSDictionary *headers = @{ @"Authorization": [NSString stringWithFormat:@"Bearer %@",[Settings authToken]],
                               @"cache-control": @"no-cache"};
    
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:testUrl];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBodyStream:isLocal ? [NSInputStream inputStreamWithFileAtPath:file.absoluteString] : [NSInputStream inputStreamWithURL:file]];
    
    return request;
}


-(void)uploadFile:(UploadedFile *) file{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    uploadStart = YES;
    if (!hud) {
        hud = [AuroraHUD uploadHUD:self.view];
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
                    hud.hudView.mode = MBProgressHUDModeCustomView;
                    hud.hudView.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"error"]];
                    hud.hudView.detailsLabel.text = @"";
                    hud.hudView.label.text = NSLocalizedString(@"Files uploaded with some errors...", @"");
                    [hud hideHUDWithDelay:0.7f];
//                    strongSelf.uploadButton.enabled = YES;
                }else{
                    [strongSelf.filesForUpload removeObject:file];
                    [strongSelf uploadAction:self];
                }

            }else{
                if (self.filesForUpload.count == 1) {
                    hud.hudView.mode = MBProgressHUDModeCustomView;
                    hud.hudView.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"success"]];
                    hud.hudView.detailsLabel.text = @"";
                    hud.hudView.label.text = NSLocalizedString(@"Files succesfully uploaded!", @"");
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
        hud.hudView.progress = progress;
        NSString *uploadStatus = [NSString stringWithFormat:@"%@ %@",[NSString transformedValue:[NSNumber numberWithLongLong:totalBytesForAllFilesSend]],[NSString transformedValue:[NSNumber numberWithLongLong:uploadSize]]];
        hud.hudView.detailsLabel.text = uploadStatus;
        DDLogDebug(@"fileName is -> %@",fileName);
        hud.hudView.label.text = fileName;
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
    [hud hideHUD];
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

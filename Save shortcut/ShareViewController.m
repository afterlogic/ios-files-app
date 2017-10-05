 //
//  ShareViewController.m
//  Save shortcut
//
//  Created by Cheshire on 16.02.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "ShareViewController.h"
#import "EXFileGalleryCollectionViewController.h"
#import "EXPreviewFileGalleryCollectionViewController.h"
#import "CurrentFilePathViewController.h"
#import "TabBarWrapperViewController.h"
#import "UploadedFile.h"
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
#import "WormholeProvider.h"
#import "AuroraHUD.h"


@interface ShareViewController ()<NSURLSessionTaskDelegate, GalleryDelegate, UploadFolderDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeight;
@property (weak, nonatomic) IBOutlet UIView *galleryContainer;
@property (weak, nonatomic) IBOutlet UIView *previewContainer;
@property (weak, nonatomic) IBOutlet UIView *uploadPathContainer;
@property (weak, nonatomic) IBOutlet UIView *userLoggedOutContainer;

- (IBAction)uploadAction:(id)sender;

@end

@implementation ShareViewController

- (void)loadView{
    [super loadView];
    [self searchFilesForUpload];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    BFLog(@"EXTENSION STARTED");
    self.navigationStack = self.navigationController.viewControllers;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    self.uploadPathContainer.hidden = YES;
    [self setCurrentUploadFolder:@"" root:@""];

    [self setupUserInterface];
    [self setupObserving];
}

-(void)setupObserving{
    [[WormholeProvider instance]cancelObservingNotification:AUWormholeNotificationUserSignOut];
    [[WormholeProvider instance]cancelObservingNotification:AUWormholeNotificationUserSignIn];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"closeExtension" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"dismissModalView" object:nil];
    
    [[WormholeProvider instance]catchNotification:AUWormholeNotificationUserSignOut handler:^(id  _Nullable messageObject) {
        [self closeExtension];
    }];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(done) name:@"closeExtension" object:nil];
}


-(void)setupUserInterface{
    hud = [AuroraHUD checkConnectionHUD:self];
    [self prepareUserInterfaceDependingUserSessionState:^{
        NSString *scheme = [Settings domainScheme];
        hud.hudView.label.text = NSLocalizedString(@"Check connection...", @"");
        if (scheme) {
            [self setupInterfaceForP8:[[Settings lastLoginServerVersion]isEqualToString:@"P8"]];
            dispatch_async(dispatch_get_main_queue(), ^(){
                [hud hideHUD];
            });
        }else{
            [[SessionProvider sharedManager]checkSSLConnection:^(NSString *domain) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [hud hideHUD];
                });
                if(domain && domain.length > 0){
                    [Settings setDomain:domain];
                    [self setupInterfaceForP8:[[Settings lastLoginServerVersion]isEqualToString:@"P8"]];
                }else{
                    [self showLoggedOutView];
                    [self hideContainers:YES];
                }
            }];
        }
    } failure:^(NSError *error) {
        [self showLoggedOutView];
        [self hideContainers:YES];
    }];
}

-(void)setupInterfaceForP8:(BOOL)isP8 {
    NSString *scheme = [Settings domainScheme];
    NSString *authToken = [Settings authToken];
    NSString *token = [Settings token];
    
    if (isP8){
        if (authToken.length==0 || !scheme) {
            [self showLoggedOutView];
            [self hideContainers:YES];
        }else{
            [self hideContainers:NO];
            [self setupForUpload];
            [self getLastUsedFolder:hud];
        }
    }else{
        if (!token || !scheme) {
            [self showLoggedOutView];
            [self hideContainers:YES];
        }else{
            [self hideContainers:NO];
            [self setupForUpload];
            [self getLastUsedFolder:hud];
        }
    }
}

- (void)getLastUsedFolder:(AuroraHUD *)folderHud{
    [[StorageManager sharedManager]getLastUsedFolderWithHandler:^(NSDictionary *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if(error){
                [self.navigationController setNavigationBarHidden:NO animated:YES];
                [self setCurrentUploadFolder:@"" root:@"personal"];
                [folderHud setHudComplitionHandler:^{
                    if(![[ErrorProvider instance]generatePopWithError:error controller:self]){
                        [self showUploadFolders];
                    }
                }];
                return;
            }
            if (result) {
                [self.navigationController setNavigationBarHidden:NO animated:YES];
                [self setCurrentUploadFolder:result[@"FullPath"] root:result[@"Type"]];
            }else{
                [self.navigationController setNavigationBarHidden:NO animated:YES];
                [self setCurrentUploadFolder:@"" root:@"personal"];
                [folderHud setHudComplitionHandler:^{
                    [self showUploadFolders];
                }];
            }
        });
        
    }];
}

-(void)hideContainers:(BOOL) hide{
    self.uploadPathContainer.hidden = hide;
}

-(void)showLoggedOutView{
    [self showLoggedOutModelView];
}

-(void)setupForUpload{
    [super setupForUpload];
}

-(void)searchFilesForUpload{
    self.filesForUpload = [NSMutableArray new];
    NSArray *imputItems = self.extensionContext.inputItems;
    BFLog(@"input items is -> %@",imputItems);
    for (NSExtensionItem *item in imputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            mediaData = nil;
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
                                return ;
                            }
                            if ([image isKindOfClass:[UIImage class]]){
                                NSData *data = [[NSData alloc]initWithData:UIImageJPEGRepresentation(image, 10.0)];
                                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                
                                NSString *uploadFileFolderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/UploadedFiles"];
                                NSError *error = [NSError new];
                                if (![[NSFileManager defaultManager] fileExistsAtPath:uploadFileFolderPath]){
                                    [[NSFileManager defaultManager] createDirectoryAtPath:uploadFileFolderPath withIntermediateDirectories:NO attributes:nil error:&error];
                                } //Create folder
                                
                                
                                NSString *name = [NSString stringWithFormat:@"upldImage_%@.jpg",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]];
                                NSString* path = [uploadFileFolderPath stringByAppendingPathComponent:name];
                                [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
                                //                                [localSaveFileLinks addObject:path];
                                
                                fileExtension = [[name componentsSeparatedByString:@"."]lastObject];
                                mediaData = [NSURL URLWithString:path];
                                UploadedFile *file = [UploadedFile new];
                                file.path = mediaData;
                                file.extension = fileExtension;
                                file.type = (NSString *)kUTTypeImage;
                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
                                file.savedLocal = YES;
                                [self.filesForUpload addObject:file];
                                return ;
                            }
                            
                            if([image isKindOfClass:[NSData class]]){
                                NSData *data = image;
                                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                
                                NSString *uploadFileFolderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/UploadedFiles"];
                                NSError *error = [NSError new];
                                if (![[NSFileManager defaultManager] fileExistsAtPath:uploadFileFolderPath]){
                                    [[NSFileManager defaultManager] createDirectoryAtPath:uploadFileFolderPath withIntermediateDirectories:NO attributes:nil error:&error];
                                } //Create folder
                                
                                
                                NSString *name = [NSString stringWithFormat:@"upldImage_%@.jpg",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]];
                                NSString* path = [uploadFileFolderPath stringByAppendingPathComponent:name];
                                [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
                                //                                [localSaveFileLinks addObject:path];
                                
                                fileExtension = [[name componentsSeparatedByString:@"."]lastObject];
                                mediaData = [[NSURL alloc ]initWithString:path];
                                UploadedFile *file = [UploadedFile new];
                                file.path = mediaData;
                                file.extension = fileExtension;
                                file.type = (NSString *)kUTTypeImage;
                                file.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[mediaData path] error:nil] fileSize];
                                file.MIMEType = [self mimeTypeForFileAtPath:mediaData.path];
                                file.savedLocal = YES;
                                [self.filesForUpload addObject:file];
                                return ;
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
    
    [self setupObserving];
}

- (void)setCurrentUploadFolder:(NSString *)folderPath root:(NSString *)root{
    [self generatePath:folderPath root:root];
    [self.navigationController popToRootViewControllerAnimated:YES];
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
}

-(void)showUploadFolders{
    DDLogDebug(@"%@", self.navigationStack);
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"MainInterface" bundle:nil];
    TabBarWrapperViewController *vc = [board instantiateViewControllerWithIdentifier:@"TabBarWrapperViewController"];
    vc.delegate = self;
    self.tabbarWrapController = vc;
    [self.navigationController pushViewController:self.tabbarWrapController animated:YES];
    self.navigationStack = self.navigationController.viewControllers;
    DDLogDebug(@"%@", self.navigationStack);
}
- (IBAction)logoutCloseButton:(id)sender {
    [self closeExtension];
}

- (IBAction)done
{
    [self closeExtension];
}

#pragma mark - Upload

- (IBAction)uploadAction:(id)sender
{
    hud = nil;
    [self runUpload];
}

-(void)runUpload{
    [self upload];
    self.uploadButton.enabled = NO;
    [self startUploadingForFiles:self.filesForUpload];
}

-(void)startUploadingForFiles:(NSArray *)files{
    [self uploadFile:[super prepareFilesForUpload:files]];
}


-(void)uploadFile:(UploadedFile *) file{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    uploadStart = YES;
    if (!hud) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            hud = [AuroraHUD uploadHUD:self.view];
        });
    }
    
    [self requestLog:file.request];
    __weak ShareViewController * weakSelf = self;
    NSURLSessionDataTask * task = [session dataTaskWithRequest:file.request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
        
        NSError  *localError = nil;
        NSString *result;
        ShareViewController *strongSelf = weakSelf;
        id json = nil;
        id stringResult = nil;
        
        if (data)
        {
            json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            stringResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        if([[Settings lastLoginServerVersion]isEqualToString:@"P8"]){
            if (stringResult != nil){
                BOOL uploadResult = [stringResult isEqualToString:@"true"];
                DDLogError(@"%@",result);
                
                if (!uploadResult)
                {
                    localError = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                }
            }else{
                localError = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }
        }else{
            if (json != nil){
                if (![json isKindOfClass:[NSDictionary class]])
                {
                    localError = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                }else if ([(NSDictionary *)json objectForKey:@"ErrorCode"]){
                    NSNumber * errorCode = [(NSDictionary *)json objectForKey:@"ErrorCode"];
                    localError = [[NSError alloc] initWithDomain:@"com.afterlogic" code:errorCode.integerValue userInfo:@{}];
                }
            }else{
                localError = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
            }
        }
        
        if (localError || error)
        {
            if (self.filesForUpload.count == 1) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [hud uploadError];
                    [hud hideHUDWithDelay:0.7f];
                });
            }else{
                [strongSelf.filesForUpload removeObject:file];
                [strongSelf runUpload];
            }
            
        }else{
            if (self.filesForUpload.count == 1) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [hud uploadSuccess];
                    [strongSelf performSelector:@selector(hideHud) withObject:nil afterDelay:0.7];
                });
            }else{
                [strongSelf.filesForUpload removeObject:file];
                [strongSelf runUpload];
            }
        }
        
        
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
    
    if ([segue.identifier isEqualToString:@"loggedOut_embed"]){
        self.loggedOutController = (UserLoggedOutViewController *)[segue destinationViewController];
    }
    
    if ([segue.identifier isEqualToString:@"push_files"]){
        TabBarWrapperViewController *vc = (TabBarWrapperViewController *)[segue destinationViewController];
        vc.delegate = self;
        self.tabbarWrapController = vc;
    }
}

@end

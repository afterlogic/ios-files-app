//
//  ExtensionParentViewController.h
//  aurorafiles
//
//  Created by Slava Kutenkov on 05/07/2017.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//

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
#import "UserLoggedOutViewController.h"

@interface ExtensionParentViewController : UIViewController{
    NSString *fileExtension;
    NSURL *mediaData;
    NSString * urlString;
    
    NSString *fileName;
    
    NSString *uploadFolderPath;
    NSString *uploadRootPath;
    
    unsigned long long uploadSize;
    
    UIAlertController * alertController;
    UIProgressView *pv;
    
    __block AuroraHUD *hud;
    
    NSMutableArray <NSMutableURLRequest *> *requestsForUpload;
    
    
    int64_t totalBytesForAllFilesSend;
    CGFloat previewLocalHeight;
    UIViewController *currentModalView;
    BOOL uploadStart;
    
    AFHTTPRequestOperationManager *manager;
    
    NSMutableArray *localSaveFileLinks;
}

@property (weak, nonatomic) EXFileGalleryCollectionViewController *galleryController;
@property (weak, nonatomic) EXPreviewFileGalleryCollectionViewController *previewController;
@property (weak, nonatomic) CurrentFilePathViewController *currentUploadPathView;
@property (weak, nonatomic) TabBarWrapperViewController *tabbarWrapController;
@property (weak, nonatomic) UserLoggedOutViewController *loggedOutController;
@property (strong, nonatomic) NSURL *movieURL;
@property (strong, nonatomic) NSMutableArray <UploadedFile *> *filesForUpload;
@property (nonatomic, retain) AVPlayerViewController *playerViewController;
@property (strong, nonatomic) NSArray <UIViewController *> *navigationStack;

-(void)prepareUserInterfaceDependingUserSessionState:(void(^)())succesHandler failure:(void(^)(NSError* error))failureHandler;

#pragma mark - Upload
-(void)setupForUpload;
-(void)upload;
-(UploadedFile *)prepareFilesForUpload:(NSArray *)files;

#pragma mark - Views
-(void)generatePath:(NSString *)folderPath root:(NSString *)root;
-(void)closeExtension;
-(void)showLoggedOutModelView;

#pragma mark - Request generators
-(NSMutableURLRequest *)generateRequestWithUrl:(NSString *)linkString data:(NSURL *)data savedLocal:(BOOL) isLocal;
-(NSMutableURLRequest *)generateP8RequestWithFile:(NSURL *)file mime:(NSString *)mime toFolderPath:(NSString *)path withName:(NSString *)name rootPath:(NSString *)rootPath savedLocal:(BOOL) isLocal;
#pragma mark - HUD

#pragma mark - Helpers
- (NSString*)mimeTypeForFileAtPath: (NSString *) path;
- (NSURL *)createInternetShortcutFile:(NSString *)name ext:(NSString *)extension link:(NSURL *)link;
- (void)requestLog:(NSURLRequest *)request;

@end

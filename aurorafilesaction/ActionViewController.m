//
//  ActionViewController.m
//  aurorafilesaction
//
//  Created by Michael Akopyants on 07/06/16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

//#import <AVFoundation/AVFoundation.h>
#import "ActionViewController.h"
#import "PopUp/PopupViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface ActionViewController ()<NSURLSessionTaskDelegate> {
    BOOL imageFound ;
    BOOL videoFound ;
    BOOL shortcutFound ;
    NSString *fileExtension;
    NSURL *mediaData;
    NSString * urlString;
    
    NSString *fileName;
    unsigned long long fileSize;
    
    UIAlertController * alertController;
    UIProgressView *pv;
    
    
    PopupViewController *allertPopUp;
    
}


@property (strong, nonatomic) NSURL *movieURL;
@property (nonatomic, retain) AVPlayerViewController *playerViewController;
@property (strong, nonatomic) IBOutlet UIView *videoAudioView;
@property(strong,nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
- (IBAction)uploadAction:(id)sender;

@end
#import <AVKit/AVKit.h>
@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get the item[s] we're handling from the extension context.
    
    // For example, look for an image and place it into an image view.
    // Replace this with something appropriate for the type[s] your extension supports.
     imageFound = videoFound = shortcutFound = NO;
    
    self.playerViewController = [[AVPlayerViewController alloc]init];
    _playerViewController.view.frame = self.videoAudioView.bounds;
    _playerViewController.showsPlaybackControls = YES;
    [self.view addSubview:_playerViewController.view];
    self.imageView.alpha = 0.0f;
    self.playerViewController.view.alpha = 0.0f;
    self.videoAudioView.alpha = 0.0f;
    
//    [self createAlertView];

    
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
//image
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                // This is an image. We'll load it, then place it in our image view.
                __weak UIImageView *imageView = self.imageView;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id image, NSError *error) {
                    if(image) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if([image isKindOfClass:[NSURL class]]) {
                                fileExtension = [[[(NSURL *)image absoluteString] componentsSeparatedByString:@"."]lastObject];
                                mediaData = image;
                                [imageView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:image]]];
                                imageView.alpha = 1.0f;
                            }
                        }];
                    }
                }];
                
                imageFound = YES;
                break;
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
                                player.view.alpha = 1.0f;
                            }
                        }];
                    }
                }];
                
                videoFound = YES;
                break;
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
                            }
                        }];
                    }
                }];
               
                shortcutFound = YES;
                break;
            }

        }
        
        if (videoFound || imageFound || shortcutFound) {
            break;
        }
    }
}


-(void)createAlertView{
    alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Uploading..", @"") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
        [self done];
    }]];
    pv = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    pv.frame = CGRectMake(20, 20, 200, 15);
    pv.progress = 0.0;
    [alertController.view addSubview:pv];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done
{
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

- (IBAction)uploadAction:(id)sender
{
    urlString = @"";
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    NSString *uploadfileName = @"";
    if (imageFound) {
        uploadfileName = [NSString stringWithFormat:@"File_%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],fileExtension];
        urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[defaults valueForKey:@"mail_domain"],@"personal",uploadfileName];
    }else if (videoFound){
        uploadfileName = [NSString stringWithFormat:@"File_%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],fileExtension];
        AVAsset *currentAsset = self.playerViewController.player.currentItem.asset;
        self.movieURL = [(AVURLAsset *)currentAsset URL];
        urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[defaults valueForKey:@"mail_domain"],@"personal",uploadfileName];
    }else if (shortcutFound){
        uploadfileName = [NSString stringWithFormat:@"InternetShortcut%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],fileExtension];
        urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[defaults valueForKey:@"mail_domain"],@"personal",uploadfileName];
    }
    NSMutableURLRequest *request = [self generateRequestWithUrl:[NSURL URLWithString:urlString]data:mediaData];
    [self uploadFileWithRequest:request data:mediaData];
    
}

-(NSMutableURLRequest *)generateRequestWithUrl:(NSURL *)url data:(NSURL *)data
{
    
    fileName = [[[data absoluteString] componentsSeparatedByString:@"/"]lastObject];
    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:[data path] error:nil] fileSize];
    
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"PUT"];
    NSString *authToken = [defaults valueForKey:@"auth_token"];
    [request setValue:authToken forHTTPHeaderField:@"Auth-Token"];

    [request setHTTPBodyStream:[[NSInputStream alloc]initWithURL:data]];
    
    [request setValue:@"personal" forHTTPHeaderField:@"Type"];
    [request setValue:@"{\"Type\":\"personal\"}" forHTTPHeaderField:@"AdditionalData"];
    
    [self requestLog:request];
    
    return request;
}


-(void)uploadFileWithRequest:(NSMutableURLRequest *) request data:(NSURL *)data
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    
    allertPopUp = [[PopupViewController alloc]initProgressAllertWithTitle:@"" message:NSLocalizedString(@"Uploading..", @"")  fileName:fileName fileSize:[NSString stringWithFormat:@"%llu",fileSize] disagreeText:NSLocalizedString(@"Cancel", @"") disagreeBlock:^{
        [self done];
    } parrentView:self];
    [allertPopUp showPopup];
    
    
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
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
                [allertPopUp closeViewWithComplition:^{
                    PopupViewController* errorPopUp = [[PopupViewController alloc] initPopUpWithOneButtonWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Operation can't be completed", @"") agreeText:NSLocalizedString(@"OK", @"") agreeBlock:^{
                        [self done];
                    } parrentView:self];
                    [errorPopUp showPopup];
                }];
                return ;
            }
            [allertPopUp closeViewWithComplition:^{
                PopupViewController* congratPopUp = [[PopupViewController alloc]initPopUpWithOneButtonWithTitle:NSLocalizedString(@"Great!", @"") message:NSLocalizedString(@"File succesfully uploaded!", @"") agreeText:NSLocalizedString(@"OK", @"") agreeBlock:^{
                      [self done];
                } parrentView:self];
                [congratPopUp showPopup];
            }];
            
        });
    }];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{

    dispatch_async(dispatch_get_main_queue(), ^(){
        [allertPopUp setProgressWihtCurrentBytes:totalBytesSent totalBytesExpectedToSend:fileSize];
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
    NSArray *stringParams = [NSArray new];
    stringParams = @[@"[InternetShortcut]",[NSString stringWithFormat:@"URL=%@",link.absoluteString]];
   
    NSString *stringToWrite = [stringParams componentsJoinedByString:@"\n"];

    NSString *shortcutName = [NSString stringWithFormat:@"%@.%@",name,extension];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:shortcutName];
    [stringToWrite writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    NSURL *resultPath = [NSURL fileURLWithPath:filePath];
    NSLog(@"%@", resultPath);
    return resultPath;
}

@end

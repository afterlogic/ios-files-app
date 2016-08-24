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
     imageFound = NO;
     videoFound = NO;
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
//                            [imageView setImage:image];
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

        }
        
        if (videoFound) {
            // We only handle one image, so stop looking for more.
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
    // Return any edited content to the host app.
    // This template doesn't do anything, so we just echo the passed in items.
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

- (IBAction)uploadAction:(id)sender
{
//    NSData * data = [NSData new];
    urlString = @"";
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    if (imageFound) {
//        UIImage * image = self.imageView.image;
        NSString *fileName = [NSString stringWithFormat:@"File_%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],fileExtension];
        urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[defaults valueForKey:@"mail_domain"],@"personal",fileName];
    }else if (videoFound){
        NSString *fileName = [NSString stringWithFormat:@"File_%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],fileExtension];
        AVAsset *currentAsset = self.playerViewController.player.currentItem.asset;
        self.movieURL = [(AVURLAsset *)currentAsset URL];
        urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[defaults valueForKey:@"mail_domain"],@"personal",fileName];
    }
    
    
//    [self generateChunks:mediaData];
    NSMutableURLRequest *request = [self generateRequestWithUrl:[NSURL URLWithString:urlString]data:mediaData];
    [self uploadFileWithRequest:request data:mediaData];
    
}

-(void)generateChunks:(NSURL *)dataURL{

    NSData* myBlob = [NSData dataWithContentsOfURL:dataURL];
    NSUInteger length = [myBlob length];
    NSUInteger chunkSize = 100 * 1024;
    NSUInteger offset = 0;
    do {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[myBlob bytes] + offset
                                             length:thisChunkSize
                                       freeWhenDone:NO];
        offset += thisChunkSize;
        // do something with chunk
//        [self uploadFileWithRequest:[self generateRequestWithUrl:[NSURL URLWithString:urlString] data:chunk]];
    } while (offset < length);
    
    
}

-(NSMutableURLRequest *)generateRequestWithUrl:(NSURL *)url data:(NSURL *)data
//-(NSMutableURLRequest *)generateRequestWithUrl:(NSURL *)url
{
    
    fileName = [[[data absoluteString] componentsSeparatedByString:@"/"]lastObject];
    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:[data path] error:nil] fileSize];
    
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"PUT"];
    NSString *authToken = [defaults valueForKey:@"auth_token"];
    [request setValue:authToken forHTTPHeaderField:@"Auth-Token"];
    
//    [request setHTTPBody:data];
    
    //second part
    [request setHTTPBodyStream:[[NSInputStream alloc]initWithURL:data]];
    
    [request setValue:@"personal" forHTTPHeaderField:@"Type"];
    [request setValue:@"{\"Type\":\"personal\"}" forHTTPHeaderField:@"AdditionalData"];
    
    [self requestLog:request];
    
    return request;
}

//-(void)uploadFileWithRequest:(NSMutableURLRequest *) request
-(void)uploadFileWithRequest:(NSMutableURLRequest *) request data:(NSURL *)data
{
//    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    
//    [self presentViewController:alertController animated:YES completion:^(){
//        
//    }];
    
    
    allertPopUp = [[PopupViewController alloc]initProgressAllertWithTitle:@"" message:NSLocalizedString(@"Uploading..", @"")  fileName:fileName fileSize:[NSString stringWithFormat:@"%llu",fileSize] disagreeText:NSLocalizedString(@"Cancel", @"") disagreeBlock:^{
        [self done];
    } parrentView:self];
    [allertPopUp showPopup];
    
//    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromFile:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    
    
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
//                [alertController dismissViewControllerAnimated:YES completion:^(){
//                    alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Operation can't be completed", @"") preferredStyle:UIAlertControllerStyleAlert];
//                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
//                        [self done];
//                    }]];
//                    [self presentViewController:alertController animated:YES completion:nil];
//                }];
                [allertPopUp closeViewWithComplition:^{
                    PopupViewController* errorPopUp = [[PopupViewController alloc] initPopUpWithOneButtonWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Operation can't be completed", @"") agreeText:NSLocalizedString(@"OK", @"") agreeBlock:^{
                        [self done];
                    } parrentView:self];
                    [errorPopUp showPopup];
                }];
                return ;
            }
//            [alertController dismissViewControllerAnimated:YES completion:^(){
//                [self done];
//            }];
            [allertPopUp closeViewWithComplition:^{
                PopupViewController* congratPopUp = [[PopupViewController alloc]initPopUpWithOneButtonWithTitle:NSLocalizedString(@"Great!", @"") message:NSLocalizedString(@"File succesfully uploaded!", @"") agreeText:NSLocalizedString(@"OK", @"") agreeBlock:^{
                      [self done];
                } parrentView:self];
                [congratPopUp showPopup];
            }];
            
        });
    }];
    [task resume];
    
    //    [[API sharedInstance] putFile:data toFolderPath:path withName:fileName completion:^(NSDictionary * response){
    //        NSLog(@"%@",response);
    //    }];

}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
//    NSLog(@"%lli",bytesSent);
//    NSLog(@"%lli",totalBytesSent);

    dispatch_async(dispatch_get_main_queue(), ^(){
//    float progress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
//        NSLog(@"pr - %f",progress);
//        [pv setProgress:progress];
    [allertPopUp setProgressWihtCurrentBytes:totalBytesSent totalBytesExpectedToSend:fileSize];
    });

    
}



-(void)requestLog:(NSURLRequest *)request {
    NSLog(@"Method: %@", request.HTTPMethod);
    NSLog(@"URL: %@", request.URL.absoluteString);
    NSLog(@"Body: %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    NSLog(@"Head: %@",request.allHTTPHeaderFields);
}

@end

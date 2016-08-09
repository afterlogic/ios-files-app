//
//  ActionViewController.m
//  aurorafilesaction
//
//  Created by Michael Akopyants on 07/06/16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

//#import <AVFoundation/AVFoundation.h>
#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

static const NSString * imageExtension = @"png";
static const NSString * videoExtension = @"mov";
 

@interface ActionViewController (){
    BOOL imageFound ;
    BOOL videoFound ;
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
//    self
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
//image
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                // This is an image. We'll load it, then place it in our image view.
                __weak UIImageView *imageView = self.imageView;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *image, NSError *error) {
                    if(image) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [imageView setImage:image];
                            imageView.alpha = 1.0f;
                        }];
                    }
                }];
                
                imageFound = YES;
                break;
            }
            
//video
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
                // This is an image. We'll load it, then place it in our image view.
                __weak AVPlayerViewController *player = self.playerViewController;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(id videoItem, NSError *error) {
                    if(videoItem) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                            [imageView setImage:image];
                            if ([videoItem isKindOfClass:[NSURL class]]) {
                                player.player  = [AVPlayer playerWithURL:(NSURL *)videoItem];
                                player.view.alpha = 1.0f;
                                NSLog(@" %@",[videoItem class]);
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
    NSData * data = [NSData new];
    NSString * urlString = @"";
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    if (imageFound) {
        UIImage * image = self.imageView.image;
        NSString *fileName = [NSString stringWithFormat:@"File_%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],imageExtension];
        data = UIImagePNGRepresentation(image);
        urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[defaults valueForKey:@"mail_domain"],@"personal",fileName];
    }else if (videoFound){
        NSString *fileName = [NSString stringWithFormat:@"File_%@.%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],videoExtension];
        AVAsset *currentAsset = self.playerViewController.player.currentItem.asset;
        self.movieURL = [(AVURLAsset *)currentAsset URL];
        data = [NSData dataWithContentsOfURL:self.movieURL];
        urlString = [NSString stringWithFormat:@"https://%@/index.php?Upload/File/%@/%@",[defaults valueForKey:@"mail_domain"],@"personal",fileName];
    }
    
    
    [self uploadFileWithRequest:[self generateRequestWithUrl:[NSURL URLWithString:urlString] data:data] ];
    
}

-(NSMutableURLRequest *)generateRequestWithUrl:(NSURL *)url data:(NSData *)data{
    NSUserDefaults * defaults = [[NSUserDefaults alloc]initWithSuiteName:@"group.afterlogic.aurorafiles"];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"PUT"];
    [request setValue:[defaults valueForKey:@"auth_token"] forHTTPHeaderField:@"Auth-Token"];
    
    [request setHTTPBody:data];
    [request setValue:@"personal" forHTTPHeaderField:@"Type"];
    [request setValue:@"{\"Type\":\"personal\"}" forHTTPHeaderField:@"AdditionalData"];
    
    return request;
}

-(void)uploadFileWithRequest:(NSMutableURLRequest *) request{
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Uploading..", @"") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
        [self done];
    }]];
    
    [self presentViewController:alertController animated:YES completion:^(){
        
    }];
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
                [alertController dismissViewControllerAnimated:YES completion:^(){
                    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Operation can't be completed", @"") preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                        [self done];
                    }]];
                    [self presentViewController:alertController animated:YES completion:nil];
                }];
                
                return ;
            }
            [alertController dismissViewControllerAnimated:YES completion:^(){
                [self done];
            }];
        });
    }];
    [task resume];
    
    
    
    
    //    [[API sharedInstance] putFile:data toFolderPath:path withName:fileName completion:^(NSDictionary * response){
    //        NSLog(@"%@",response);
    //    }];

}



@end

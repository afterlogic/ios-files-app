//
//  ExtensionParentViewController.m
//  aurorafiles
//
//  Created by Slava Kutenkov on 05/07/2017.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//

#import "ExtensionParentViewController.h"


@interface ExtensionParentViewController ()

@end

@implementation ExtensionParentViewController

-(void)loadView{
    [super loadView];
    [Bugfender enableAllWithToken:@"XjOPlmw9neXecfebLqUwiSfKOCLxwCHT"];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    
    [[DataBaseProvider sharedProvider] setupCoreDataStack];
    [[StorageManager sharedManager]setupDBProvider:[DataBaseProvider sharedProvider]];
    [[StorageManager sharedManager]setupFileOperationsProvider:[FileOperationsProvider sharedProvider]];
    self.navigationStack = [NSArray new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareUserInterfaceDependingUserSessionState:(void(^)())succesHandler failure:(void(^)(NSError* error))failureHandler{
    [[SessionProvider sharedManager]updateDomainVersion:^{
        [[SessionProvider sharedManager]userData:^(BOOL authorised, NSError *error) {
            NSError *notLoggedIn = [[ErrorProvider instance]generateError:@"1001"];
            if (error) {
                failureHandler(error);
                return;
            }
            if(!authorised){
                failureHandler(notLoggedIn);
                return;
            }
            if(![Settings getIsLogedIn]){
                failureHandler(notLoggedIn);
                return;
            }
            
            succesHandler();
        }];
 
    }];
}

#pragma mark - Upload helpers

- (void)setupForUpload{
    manager = [AFHTTPRequestOperationManager manager];
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    manager.securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy.validatesDomainName = NO;
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    totalBytesForAllFilesSend = 0;
    uploadStart = NO;
    localSaveFileLinks = [[NSMutableArray alloc]init];
}

-(void)upload{
    urlString = @"";
    requestsForUpload = [NSMutableArray new];
    
    for (UploadedFile *file in self.filesForUpload){
        if ([file.type isEqualToString:(NSString *)kUTTypeURL]) {
            NSString *lastPathComponent = [file.path lastPathComponent];
            file.name = lastPathComponent;
        }else{
            file.name = [[[file.path absoluteString] componentsSeparatedByString:@"/"]lastObject];
        }
        if ([[Settings lastLoginServerVersion]isEqualToString:@"P8"]) {
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
}

-(UploadedFile *)prepareFilesForUpload:(NSArray *)files{
    
    UploadedFile *currentFile = files.firstObject;
    fileName = currentFile.name;
    if (uploadStart) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            fileName = currentFile.name;
        });
    }
    return currentFile;
}

#pragma mark - Views
-(void)generatePath:(NSString *)folderPath root:(NSString *)root{
    uploadFolderPath = folderPath;
    uploadRootPath = root;
    NSString *targetPath = [folderPath componentsSeparatedByString:@"/"].lastObject;
    [self.currentUploadPathView setUploadPath:[NSString stringWithFormat:@"%@ : %@",root,targetPath]];
}

-(void)closeExtension{
    BFLog(@"EXTENSION END WORK");
    [manager.operationQueue cancelAllOperations];
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

- (void)showLoggedOutModelView{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"MainInterface" bundle:nil];
    UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"UserLoggedOutViewController"];
    vc.view.hidden = NO;
    
    if (![NSStringFromClass([self.presentedViewController class]) isEqualToString:NSStringFromClass([UserLoggedOutViewController class])]){
        [self presentViewController:vc animated:YES completion:nil];
    }
}
#pragma mark - Request generators

-(NSMutableURLRequest *)generateRequestWithUrl:(NSString *)linkString data:(NSURL *)data savedLocal:(BOOL) isLocal
{
    NSURL *url = [NSURL URLWithString:[linkString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"PUT"];
    
    NSString *authToken = [Settings authToken];
    [request setValue:authToken forHTTPHeaderField:@"Auth-Token"];
    
    [request setHTTPBodyStream:isLocal ? [NSInputStream inputStreamWithFileAtPath:data.absoluteString] :[[NSInputStream alloc]initWithURL:data]];
    
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

#pragma mark - Helpers
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

-(void)requestLog:(NSURLRequest *)request {
    BFLog(@"Method: %@", request.HTTPMethod);
    BFLog(@"URL: %@", request.URL.absoluteString);
    BFLog(@"Body: %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    BFLog(@"Head: %@",request.allHTTPHeaderFields);
}

@end

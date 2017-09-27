//
//  SocialLoginWebPopupViewController.m
//  aurorafiles
//
//  Created by Артем Ковалев on 05.09.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "SocialLoginWebPopupViewController.h"
#import "Settings.h"
#import "MBProgressHUD.h"

@interface SocialLoginWebPopupViewController ()<UIWebViewDelegate>{
    NSURLRequest *previousRequest;
}
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation SocialLoginWebPopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView.delegate = self;
    self.webView.scrollView.bounces = NO;
    
    
//    NSMutableDictionary *currentHeaderFields = self.authRequest.allHTTPHeaderFields.mutableCopy;
//    [currentHeaderFields removeObjectForKey:@"User-Agent"];
    
    NSString *userAgent = fakeUserAgent;
    NSDictionary *dictionary = [[NSDictionary alloc]initWithObjectsAndKeys:userAgent,@"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:(dictionary)];
    
//    NSMutableURLRequest *updatedRequest = [NSURLRequest requestWithURL:self.authRequest.URL].mutableCopy;
//    [updatedRequest setAllHTTPHeaderFields:nil];
//    [updatedRequest addValue:fakeUserAgent forHTTPHeaderField:@"User-Agent"];
//    [updatedRequest addValue:@"0" forHTTPHeaderField:@"Upgrade-Insecure-Requests"];
//    DDLogDebug(@"updated request headers - > %@",updatedRequest.allHTTPHeaderFields);
    [MBProgressHUD showHUDAddedTo:self.webView animated:YES];
    [self.webView loadRequest:self.authRequest];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Actions

- (IBAction)closePopUpAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WebView Delegates

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    DDLogDebug(@"current request host - > %@",request.URL.host);
    BOOL shouldStart = NO;
    NSString *currentRequestHost = request.URL.host;
    NSString *previousRequestHost = previousRequest.URL.host;
    if (previousRequestHost!=nil && [previousRequestHost containsString:[Settings domain]] && [currentRequestHost containsString:[Settings domain]]){
        NSString *authToken = [self getAuthTokenFromCookie];
        if (authToken != nil) {
            shouldStart = NO;
            [self.delegate authToken:authToken];
        }else{
            shouldStart = NO;
            NSError *webAuthError = [[ErrorProvider instance]generateError:@"902"];
            [self.delegate loginError:webAuthError];
        }
    }else{
        shouldStart = YES;
    }
    previousRequest = request;
    return shouldStart;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [MBProgressHUD hideHUDForView:webView animated:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [MBProgressHUD hideHUDForView:webView animated:YES];
}

- (NSString *)getAuthTokenFromCookie{
    NSString *authToken = nil;
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *hostCookies = [cookieJar cookies];
    DDLogDebug(@"%@",hostCookies);
    for (cookie in hostCookies){
        if([cookie.name isEqualToString:@"AuthToken"]){
            DDLogDebug(@"AuthCoockie is -> %@",cookie);
            authToken = cookie.value;
        }
    }

    return authToken;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

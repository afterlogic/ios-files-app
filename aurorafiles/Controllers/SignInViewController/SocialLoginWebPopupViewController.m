//
//  SocialLoginWebPopupViewController.m
//  aurorafiles
//
//  Created by Артем Ковалев on 05.09.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "SocialLoginWebPopupViewController.h"
#import "Settings.h"

@interface SocialLoginWebPopupViewController ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation SocialLoginWebPopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView.delegate = self;
    
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
//    DDLogDebug(@"current request URL - > %@",request.URL);
    DDLogDebug(@"current request host - > %@",request.URL.host);
    BOOL shouldStart = NO;
    NSString * currentRequestHost = request.URL.host;
    if ([currentRequestHost containsString:[Settings domain]]){
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray *hostCookies = [cookieJar cookies];
        for (cookie in hostCookies){
            if([cookie.name isEqualToString:@"AuthToken"]){
                shouldStart = NO;
                DDLogDebug(@"AuthCoockie is -> %@",cookie);
                [self.delegate authToken:cookie.value];
            }
        }
        DDLogDebug(@"%@",hostCookies);
        shouldStart = YES;
    }else{
        shouldStart = YES;
    }
    
    return shouldStart;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
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

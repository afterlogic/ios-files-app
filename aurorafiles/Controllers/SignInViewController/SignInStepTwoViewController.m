//
//  SignInStepTwoViewController.m
//  aurorafiles
//
//  Created by Артем Ковалев on 05.09.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "SignInStepTwoViewController.h"
#import "Settings.h"
#import "SessionProvider.h"
#import "KeychainWrapper.h"
#import "MBProgressHUD.h"
#import <BugfenderSDK/BugfenderSDK.h>
#import "NSString+Validators.h"
#import "StorageManager.h"
#import "WormholeProvider.h"
#import "SocialLoginWebPopupViewController.h"

@interface SignInStepTwoViewController () <UIWebViewDelegate, UITextFieldDelegate, SocialLoginDelegate>{
    UITextField *activeField;
    UITapGestureRecognizer *tapRecognizer;
    BOOL alertViewIsShow;
    NSURLRequest *authRequest;
    SocialLoginWebPopupViewController *socialLoginWebView;
    BOOL webViewShouldStartLoadRequest;
    NSString *socialLoginLink;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextFieldCustomEdges *emailField;
@property (weak, nonatomic) IBOutlet UITextFieldCustomEdges *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *SignInButton;
@property (weak, nonatomic) IBOutlet UIWebView *loginWebView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) NSLayoutConstraint *contentHeight;
@property (strong, nonatomic) __block SessionProvider *sessionProvider;
@end

@implementation SignInStepTwoViewController

#pragma mark - ViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self registerForKeyboardNotifications];
    
    tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideKeyboard)];
    [self.scrollView addGestureRecognizer:tapRecognizer];
    
    self.emailField.text = [Settings login];
    UIColor *borderColor = [UIColor colorWithWhite:243/255.0f alpha:1.0f];
    
    self.emailField.layer.borderWidth = 0.5f;
    self.emailField.layer.borderColor = borderColor.CGColor;
    
    self.passwordField.layer.borderWidth = 0.5f;
    self.passwordField.layer.borderColor = borderColor.CGColor;
    
    self.emailField.delegate = self;
    self.passwordField.delegate = self;
    self.contentHeight.constant = CGRectGetHeight(self.view.bounds);
    
    
    [self.backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    
    alertViewIsShow = NO;
    webViewShouldStartLoadRequest = NO;
    
    [[WormholeProvider instance]sendNotification:AUWormholeNotificationUserSignOut object:nil];
    
    DDLogDebug(@"scheme -> %@ domain -> %@",[Settings domainScheme], [Settings domain]);
    socialLoginLink = [NSString stringWithFormat:@"%@%@%@",[Settings domainScheme],[Settings domain],socialLoginEndPoint];
    NSURL *socialLoginPageUrl = [NSURL URLWithString:socialLoginLink];
    NSURLRequest *webViewRequest = [NSURLRequest requestWithURL:socialLoginPageUrl];
//    NSURLRequest *webViewRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://0.0.0.0:8080"]];
    
    if (self.haveWebAuth){
        [self.scrollView setScrollEnabled:YES];
        self.loginWebView.delegate = self;
        [self.loginWebView.scrollView setScrollEnabled: NO];
        self.loginWebView.opaque = NO;
        self.loginWebView.backgroundColor = [UIColor clearColor];
        [self.loginWebView loadRequest:webViewRequest];
        [MBProgressHUD showHUDAddedTo:self.loginWebView animated:YES];
    }else{
        self.loginWebView.alpha = 0;
        [self.scrollView setScrollEnabled:NO];
    }

    
}

-(void)viewWillAppear:(BOOL)animated{
    self.sessionProvider = [SessionProvider sharedManager];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

-(void)viewDidAppear:(BOOL)animated{
    
}

-(void)viewWillDisappear:(BOOL)animated{
    
}

-(void)viewDidDisappear:(BOOL)animated{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Button Actions

- (void)backAction{
    DDLogDebug(@"navigation item -> %@",self.navigationItem);
    DDLogDebug(@"navigation controller -> %@",self.navigationController);
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - WebView Delegates

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"webView start load ->  %@",request.URL);
    NSLog(@"base url host is -> %@",request.URL.host);
    NSString * currentRequestURL = request.URL.absoluteString;
    if ([currentRequestURL isEqualToString:socialLoginLink]){
        webViewShouldStartLoadRequest = YES;
    }else{
        webViewShouldStartLoadRequest = NO;
        authRequest = request;
        [self performSegueWithIdentifier:@"showModalWebView" sender:nil];
    }
    return webViewShouldStartLoadRequest;
//    return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
//    DDLogDebug(@"webView did start load ->  %@",webView.request.URL);
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
//    DDLogDebug(@"webView did finish load ->  %@",webView.request.URL);
//    CGFloat webViewHeight = self.loginWebView.scrollView.contentSize.height;
//    DDLogDebug(@"webView height is -> %f", webViewHeight);
    [MBProgressHUD hideHUDForView:webView animated:YES];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if (webViewShouldStartLoadRequest){
        [[ErrorProvider instance] generatePopWithError:error controller:self customCancelAction:^(UIAlertAction *action) {
            alertViewIsShow = NO;
        }];
        alertViewIsShow = YES;
    }
}

#pragma mark - TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:self.emailField])
    {
        [self.passwordField becomeFirstResponder];
    }
    if ([textField isEqual:self.passwordField])
    {
        [self.passwordField resignFirstResponder];
        [self auth:self.SignInButton];
        activeField = nil;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}

- (IBAction)auth:(UIButton*)sender
{
    [activeField resignFirstResponder];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self checkEmail]) {
            return;
        }
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self logInAction];
    });
    

}

- (BOOL)checkEmail{
    if (self.emailField.text.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!alertViewIsShow) {
                NSError *error = [NSError errorWithDomain:@"" code:4061 userInfo:nil];
                [[ErrorProvider instance] generatePopWithError:error controller:self customCancelAction:^(UIAlertAction *action) {
                    alertViewIsShow = NO;
                }];
                alertViewIsShow = YES;
            }
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        return NO;
    }
    return YES;
}

- (void)logInAction{
    [self.sessionProvider loginEmail:self.emailField.text withPassword:self.passwordField.text completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (error){
                [[ErrorProvider instance] generatePopWithError:error controller:self customCancelAction:^(UIAlertAction *action) {
                    alertViewIsShow = NO;
//                    [self clear];
                }];
                alertViewIsShow = YES;
            }else{
                [Settings setLogin:self.emailField.text];
                [Settings setPassword:self.passwordField.text];
                [Settings setIsLogedIn:YES];
                [[WormholeProvider instance]sendNotification:AUWormholeNotificationUserSignIn object:nil];
                [self performSegueWithIdentifier:@"succeedLogin" sender:self];
            }
        });
    }];
}



#pragma mark - Keyboard Observers

-(void)hideKeyboard{
    [activeField endEditing:YES];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:activeField.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

#pragma mark - SocialLoginDelegate Methods

-(void)authToken:(NSString *)token{
    DDLogDebug(@"new token -> %@", token);
    [Settings setAuthToken:token];
    [socialLoginWebView dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:@"succeedLogin" sender:self];
    }];
}

- (void)loginError:(NSError *)error{
    [socialLoginWebView dismissViewControllerAnimated:YES completion:^{
        [[ErrorProvider instance]generatePopWithError:error controller:self];
    }];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"showModalWebView"]) {
        socialLoginWebView = segue.destinationViewController;
        socialLoginWebView.authRequest = authRequest;
        socialLoginWebView.delegate = self;
    }
}


#pragma mark - Utilities

-(void)clear{
    [Settings clearSettings];
    [[StorageManager sharedManager]clear];
    [self.sessionProvider clear];
}

-(void)removeAllCookies{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieJar cookies];
    for (cookie in cookies) {
        [cookieJar deleteCookie:cookie];
    }
}

@end

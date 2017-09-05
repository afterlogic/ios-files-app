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

@interface SignInStepTwoViewController () <UIWebViewDelegate, UITextFieldDelegate>{
    UITextField *activeField;
    UITapGestureRecognizer *tapRecognizer;
    BOOL alertViewIsShow;
    NSURLRequest *authRequest;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextFieldCustomEdges *emailField;
@property (weak, nonatomic) IBOutlet UITextFieldCustomEdges *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *SignInButton;
@property (weak, nonatomic) IBOutlet UIWebView *loginWebView;
@property (weak, nonatomic) NSLayoutConstraint *contentHeight;
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
    
    alertViewIsShow = NO;
    
    [[WormholeProvider instance]sendNotification:AUWormholeNotificationUserSignOut object:nil];
    
    DDLogDebug(@"scheme -> %@ domain -> %@",[Settings domainScheme], [Settings domain]);
    NSURL *socialLoginPageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",[Settings domainScheme],[Settings domain],socialLoginEndPoint]];
    NSURLRequest *webViewRequest = [NSURLRequest requestWithURL:socialLoginPageUrl];
    self.loginWebView.delegate = self;
    [self.loginWebView.scrollView setScrollEnabled: NO];
    [self.loginWebView loadRequest:webViewRequest];
}

-(void)viewWillAppear:(BOOL)animated{

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
#pragma mark - WebView Delegates

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    BOOL shouldStart = NO;
    DDLogDebug(@"webView start load ->  %@",request.URL);
    DDLogDebug(@"base url is -> %@",request.URL.host);
    NSString * currentRequestHost = request.URL.host;
    if ([currentRequestHost containsString:[Settings domain]]){
        shouldStart = YES;
    }else{
        authRequest = request;
        [self performSegueWithIdentifier:@"showModalWebView" sender:nil];
    }
    return shouldStart;
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    DDLogDebug(@"webView did start load ->  %@",webView.request.URL);
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    DDLogDebug(@"webView did finish load ->  %@",webView.request.URL);
//    CGFloat webViewHeight = self.loginWebView.scrollView.contentSize.height;
//    DDLogDebug(@"webView height is -> %f", webViewHeight);
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [[ErrorProvider instance] generatePopWithError:error controller:self customCancelAction:^(UIAlertAction *action) {
        alertViewIsShow = NO;
    }];
    alertViewIsShow = YES;
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
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    });
    
    if (![self checkEmail]) {
        return;
    }
    
//    if (![self checkDomain]) {
//        return;
//    }
    
    
    [self logInAction];
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


#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"showModalWebView"]) {
        SocialLoginWebPopupViewController *vc = segue.destinationViewController;
        vc.authRequest = authRequest;
    }
}


@end

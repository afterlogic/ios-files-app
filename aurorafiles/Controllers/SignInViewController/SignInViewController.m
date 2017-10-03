//
//  SignInViewController.m
//  p7mobile
//
//  Created by Akopyants Michael on 24/03/15.
//  Copyright (c) 2015 Afterlogic Rus. All rights reserved.
//

#import "SignInViewController.h"
#import "SignInStepTwoViewController.h"
#import "Settings.h"
#import "SessionProvider.h"
#import "KeychainWrapper.h"
#import "MBProgressHUD.h"
#import <BugfenderSDK/BugfenderSDK.h>
#import "NSString+Validators.h"
#import "StorageManager.h"
#import "WormholeProvider.h"

//#import "StorageProvider.h"
@interface SignInViewController () <UIAlertViewDelegate>
{
	UITextField *activeField;
    UITapGestureRecognizer *tapRecognizer;
    BOOL alertViewIsShow;
    BOOL secondStepHaveWebAuth;
}
@property (strong, nonatomic) __block SessionProvider *sessionProvider;
@end

@implementation SignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self registerForKeyboardNotifications];
    
    tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideKeyboard)];
    [self.scrollView addGestureRecognizer:tapRecognizer];

    self.domainField.text = [[[NSURL URLWithString:[Settings domain]] resourceSpecifier]stringByReplacingOccurrencesOfString:@"//" withString:@""];
//    self.emailField.text = [Settings login];
    UIColor *borderColor = [UIColor colorWithWhite:243/255.0f alpha:1.0f];
    
    self.domainField.layer.borderWidth = 0.5f;
    self.domainField.layer.borderColor = borderColor.CGColor;
    
//    self.emailField.layer.borderWidth = 0.5f;
//    self.emailField.layer.borderColor = borderColor.CGColor;
    
//    self.passwordField.layer.borderWidth = 0.5f;
//    self.passwordField.layer.borderColor = borderColor.CGColor;
    
	self.domainField.delegate = self;
//	self.emailField.delegate = self;
//	self.passwordField.delegate = self;
	self.contentHeight.constant = CGRectGetHeight(self.view.bounds);
    
    alertViewIsShow = NO;
    secondStepHaveWebAuth = NO;
    
    [[WormholeProvider instance]sendNotification:AUWormholeNotificationUserSignOut object:nil];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.sessionProvider = [SessionProvider sharedManager];
    [self.navigationController setNavigationBarHidden:YES];
    [self clear];

}

-(void)hideKeyboard{
    [activeField endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([textField isEqual:self.domainField])
	{
//        [self.passwordField resignFirstResponder];
        [self auth:self.signInButton];
        activeField = nil;
	}
    
    
//	if ([textField isEqual:self.emailField])
//	{
//		[self.passwordField becomeFirstResponder];
//	}
//	if ([textField isEqual:self.passwordField])
//	{
//		[self.passwordField resignFirstResponder];
//		[self auth:self.signInButton];
//		activeField = nil;
//	}
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
    
//    if (self.emailField.text.length == 0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (!alertViewIsShow) {
//                NSError *error = [NSError errorWithDomain:@"" code:4061 userInfo:nil];
//                [[ErrorProvider instance] generatePopWithError:error controller:self customCancelAction:^(UIAlertAction *action) {
//                    alertViewIsShow = NO;
//                }];
//                alertViewIsShow = YES;
//            }
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//            return;
//        });
//    }
    
//    if (self.domainField.text.length == 0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if(!alertViewIsShow){
//                
//                NSError *error = [NSError errorWithDomain:@"" code:4062 userInfo:nil];
//                [[ErrorProvider instance] generatePopWithError:error controller:self customCancelAction:^(UIAlertAction *action) {
//                    alertViewIsShow = NO;
//                }];
//                alertViewIsShow = YES;
//            }
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//        });
//        return;
//    }
    
//    if (![self checkEmail]) {
//        return;
//    }
    
    if (![self checkDomain]) {
        return;
    }
    
    [Settings setDomain:self.domainField.text];
    
    [self connectToHost];
}

//- (BOOL)checkEmail{
//    if (self.emailField.text.length == 0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (!alertViewIsShow) {
//                NSError *error = [NSError errorWithDomain:@"" code:4061 userInfo:nil];
//                [[ErrorProvider instance] generatePopWithError:error controller:self customCancelAction:^(UIAlertAction *action) {
//                    alertViewIsShow = NO;
//                }];
//                alertViewIsShow = YES;
//            }
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//        });
//        return NO;
//    }
//    return YES;
//}

- (BOOL)checkDomain{
    if (self.domainField.text.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!alertViewIsShow){
                NSError *error = [NSError errorWithDomain:@"" code:4062 userInfo:nil];
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

- (void)connectToHost{
    __weak typeof (self) weakSelf = self;
    [self.sessionProvider checkSSLConnection:^(NSString *domain) {
        typeof(self)strongSelf = weakSelf;
        
        if (domain && domain.length) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:strongSelf.view animated:YES];
            
                [strongSelf.sessionProvider checkWebAuthExistance:^(BOOL haveWebAuth, NSError *error) {
                    if (error){
                        secondStepHaveWebAuth = NO;
                        [strongSelf performSegueWithIdentifier:@"hostHasBeenAllowed" sender:self];
                    }
                    else{
                        secondStepHaveWebAuth = haveWebAuth;
                        [strongSelf performSegueWithIdentifier:@"hostHasBeenAllowed" sender:self];
                    }
                }];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!alertViewIsShow) {
                    NSError *error = [[ErrorProvider instance]generateError:@"4001"];
                    [[ErrorProvider instance] generatePopWithError:error controller:strongSelf customCancelAction:^(UIAlertAction *action) {
                        alertViewIsShow = NO;
                    }];
                    [strongSelf clear];
                    alertViewIsShow = YES;
                }
                [MBProgressHUD hideHUDForView:strongSelf.view animated:YES];
            });
        }
    }];
}
//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
//    if (buttonIndex == [alertView cancelButtonIndex]) {
//        alertViewIsShow = NO;
//    }
//}

-(void)offlineAuth{
//    [self dismissViewControllerAnimated:YES completion:^(){
//        [self.delegate userWasSigneInOffline];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationSignInOffline" object:self];
//    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Called when the UIKeyboardDidShowNotification is sent.
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

#pragma mark - Utilities

-(void)clear{
    [Settings clearSettings];
    [[StorageManager sharedManager]clear];
    [self.sessionProvider clear];
    [self removeAllCookies];
}

-(void)removeAllCookies{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieJar cookies];
    for (cookie in cookies) {
        [cookieJar deleteCookie:cookie];
    }
}


#pragma mark - Navigation
 
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"hostHasBeenAllowed"]){
        SignInStepTwoViewController *secondAuthStepVC = segue.destinationViewController;
        secondAuthStepVC.haveWebAuth = secondStepHaveWebAuth;
    }
// Get the new view controller using [segue destinationViewController].
// Pass the selected object to the new view controller.
}


@end

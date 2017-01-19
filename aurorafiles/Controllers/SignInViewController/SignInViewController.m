//
//  SignInViewController.m
//  p7mobile
//
//  Created by Akopyants Michael on 24/03/15.
//  Copyright (c) 2015 Afterlogic Rus. All rights reserved.
//

#import "SignInViewController.h"
#import "Settings.h"
#import "SessionProvider.h"
#import "KeychainWrapper.h"
#import "MBProgressHUD.h"
#import <BugfenderSDK/BugfenderSDK.h>
#import "NSString+Validators.h"
#import "UIAlertView+Errors.h"
#import "StorageManager.h"

//#import "StorageProvider.h"
@interface SignInViewController () <UIAlertViewDelegate>
{
	UITextField *activeField;
    BOOL alertViewIsShow;
}
@end

@implementation SignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self registerForKeyboardNotifications];

    self.domainField.text = [[[NSURL URLWithString:[Settings domain]] resourceSpecifier]stringByReplacingOccurrencesOfString:@"//" withString:@""];
    self.emailField.text = [Settings login];
    UIColor *borderColor = [UIColor colorWithWhite:243/255.0f alpha:1.0f];
    
    self.domainField.layer.borderWidth = 0.5f;
    self.domainField.layer.borderColor = borderColor.CGColor;
    
    self.emailField.layer.borderWidth = 0.5f;
    self.emailField.layer.borderColor = borderColor.CGColor;
    
    self.passwordField.layer.borderWidth = 0.5f;
    self.passwordField.layer.borderColor = borderColor.CGColor;
    
	self.domainField.delegate = self;
	self.emailField.delegate = self;
	self.passwordField.delegate = self;
	self.contentHeight.constant = CGRectGetHeight(self.view.bounds);
    
    alertViewIsShow = NO;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self clear];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([textField isEqual:self.domainField])
	{
		[self.emailField becomeFirstResponder];
	}
	if ([textField isEqual:self.emailField])
	{
		[self.passwordField becomeFirstResponder];
	}
	if ([textField isEqual:self.passwordField])
	{
		[self.passwordField resignFirstResponder];
		[self auth:self.signInButton];
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
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (self.emailField.text.length == 0) {
        if (!alertViewIsShow) {
            NSError *error = [NSError errorWithDomain:@"" code:4061 userInfo:nil];
            [UIAlertView generatePopupWithError:error forVC:self];
            alertViewIsShow = YES;
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        return;
    }
    
    if (self.domainField.text.length == 0) {
        if(!alertViewIsShow){
            NSError *error = [NSError errorWithDomain:@"" code:4062 userInfo:nil];
            [UIAlertView generatePopupWithError:error forVC:self];
            alertViewIsShow = YES;
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        return;
    }
    
	[Settings setDomain:self.domainField.text];
    
    [[SessionProvider sharedManager]checkSSLConnection:^(NSString *domain) {
        if (domain && domain.length) {
        [[SessionProvider sharedManager]loginEmail:self.emailField.text withPassword:self.passwordField.text completion:^(BOOL success, NSError *error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (error){
                [UIAlertView generatePopupWithError:error forVC:self];
            }else{
                [Settings setLogin:self.emailField.text];
                [Settings setPassword:self.passwordField.text];

                [self performSegueWithIdentifier:@"succeedLogin" sender:self];
//                [self dismissViewControllerAnimated:YES completion:^(){
//                    [self.delegate userWasSignedIn];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationSignIn" object:self];
//                }];
            }
        }];
        }else{
            if (!alertViewIsShow) {
                NSError *error = [NSError errorWithDomain:@"" code:401 userInfo:nil];
                [UIAlertView generatePopupWithError:error forVC:self];
                [self clear];
                alertViewIsShow = YES;
            }
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [alertView cancelButtonIndex]) {
        alertViewIsShow = NO;
    }
}

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

-(void)clear{
    [Settings clearSettings];
    [[StorageManager sharedManager]clear];
    [[SessionProvider sharedManager]clear];
}

@end

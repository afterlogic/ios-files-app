//
//  SignInViewController.m
//  p7mobile
//
//  Created by Akopyants Michael on 24/03/15.
//  Copyright (c) 2015 Afterlogic Rus. All rights reserved.
//

#import "SignInViewController.h"
#import "Settings.h"
#import "Api.h"
#import "SessionProvider.h"
#import "KeychainWrapper.h"
#import "MBProgressHUD.h"
#import <BugfenderSDK/BugfenderSDK.h>
#import "NSString+Validators.h"

//#import "StorageProvider.h"
@interface SignInViewController () <UIAlertViewDelegate>
{
	UITextField *activeField;
}
@end

@implementation SignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self registerForKeyboardNotifications];
	self.domainField.text = [Settings domain];
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
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [Settings setAuthToken:nil];
    [Settings setToken:nil];
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
    if (![self.emailField.text isValidEmail]) {
        NSError *error;
        NSString * text = NSLocalizedString(@"You have entered an invalid e-mail address. Please try again", @"");
        if ([error localizedDescription])
        {
            text = [NSString stringWithFormat:@"%@",[error localizedDescription]];
            BFLog(@"email error - > %@",text);
        }
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", @"") message:text delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
        a.delegate = self;
        [a show];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        return;
    }
	[Settings setDomain:self.domainField.text];
	[SessionProvider authroizeEmail:self.emailField.text withPassword:self.passwordField.text completion:^(BOOL authorized, NSError * error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
		if (authorized)
		{
            [Settings setLogin:self.emailField.text];
            [Settings setPassword:self.passwordField.text];
			[self dismissViewControllerAnimated:YES completion:^(){
                [self.delegate userWasSignedIn];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationSignIn" object:self];
			}];
		}
		else
		{
            NSLog(@"%@",error);
            NSString * text = NSLocalizedString(@"The e-mail or password you entered is incorrect", @"");
            if ([error localizedDescription])
            {
                text = [NSString stringWithFormat:@"%@ %@",[error localizedDescription], NSLocalizedString(@"Application work in offline mode",nil)];
                BFLog(@"login error - > %@",text);
            }
			UIAlertView *a = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", @"") message:text delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
            a.delegate = self;
			[a show];
		}
	}];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [alertView cancelButtonIndex]) {
//        [self offlineAuth];
    }
}

-(void)offlineAuth{
    [self dismissViewControllerAnimated:YES completion:^(){
        [self.delegate userWasSigneInOffline];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationSignInOffline" object:self];
    }];
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

@end

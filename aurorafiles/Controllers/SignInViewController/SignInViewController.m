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
//#import "StorageProvider.h"

@interface SignInViewController ()
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
	self.domainField.delegate = self;
	self.emailField.delegate = self;
	self.passwordField.delegate = self;
	self.contentHeight.constant = CGRectGetHeight(self.view.bounds);
    // Do any additional setup after loading the view.
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
	[Settings setDomain:self.domainField.text];
	[SessionProvider authroizeEmail:self.emailField.text withPassword:self.passwordField.text completion:^(BOOL authorized) {

		if (authorized)
		{
			[self dismissViewControllerAnimated:YES completion:^(){
			}];
		}
		else
		{
			UIAlertView *a = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", @"") message:NSLocalizedString(@"The username or password you entered is incorrect", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
			[a show];
		}
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

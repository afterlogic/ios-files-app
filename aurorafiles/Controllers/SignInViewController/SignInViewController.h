//
//  SignInViewController.h
//  p7mobile
//
//  Created by Akopyants Michael on 24/03/15.
//  Copyright (c) 2015 Afterlogic Rus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignInViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *domainField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentHeight;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
- (IBAction)auth:(id)sender;
@end

//
//  SignInViewController.h
//  p7mobile
//
//  Created by Akopyants Michael on 24/03/15.
//  Copyright (c) 2015 Afterlogic Rus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextFieldCustomEdges.h"
#import "SignControllerDelegate.h"

@interface SignInViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextFieldCustomEdges *domainField;
@property (weak, nonatomic) IBOutlet UITextFieldCustomEdges *emailField;
@property (weak, nonatomic) IBOutlet UITextFieldCustomEdges *passwordField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentHeight;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) id <SignControllerDelegate> delegate;
- (IBAction)auth:(id)sender;
@end

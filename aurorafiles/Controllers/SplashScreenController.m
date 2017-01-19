//
// Created by Cheshire on 19.01.17.
// Copyright (c) 2017 afterlogic. All rights reserved.
//

#import "SplashScreenController.h"
#import "SignInViewController.h"
#import "Settings.h"


@interface SplashScreenController(){
    
}
@property (weak, nonatomic) IBOutlet UIImageView *filledAppLogo;
@property (weak, nonatomic) IBOutlet UIImageView *simpleAppLogo;


@end;

@implementation SplashScreenController

-(void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [UIView animateWithDuration:0.5f animations:^{
        self.filledAppLogo.alpha = 1.0f;
    } completion:^(BOOL finished) {
        if(finished){
            [self checkAppState];
        }
    }];


}

- (void)checkAppState{
    if (![Settings version] || ![Settings domain]){
        [self showSignInScreen];
        return;
    }
    if (![Settings token] && ![Settings password] && ![Settings currentAccount]) {
        [self showSignInScreen];
        return;
    }

    [self showFilesScreen];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)showSignInScreen{
//    SignInViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
//    signIn.delegate = self;
//    [self presentViewController:signIn animated:YES completion:nil];
    [self performSegueWithIdentifier:@"showSignInView" sender:self];
}

-(void)showFilesScreen{
    [self performSegueWithIdentifier:@"showFilesView" sender:self];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"showSignInView"]){
        SignInViewController *vc = segue.destinationViewController;
        vc.delegate = self;
    }

    if([segue.identifier isEqualToString:@"showFilesView"]){

    }


}

@end

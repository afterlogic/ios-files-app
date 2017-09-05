//
//  SocialLoginWebPopupViewController.m
//  aurorafiles
//
//  Created by Артем Ковалев on 05.09.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "SocialLoginWebPopupViewController.h"

@interface SocialLoginWebPopupViewController ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation SocialLoginWebPopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView.delegate = self;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

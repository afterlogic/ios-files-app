//
//  UserLoggedOutViewController.m
//  aurorafiles
//
//  Created by Slava Kutenkov on 04/07/2017.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "UserLoggedOutViewController.h"
#import "AFNetworking.h"
#import "AFNetworkActivityLogger.h"
#import <BugfenderSDK/BugfenderSDK.h>
#import "WormholeProvider.h"

@interface UserLoggedOutViewController (){
    AFHTTPRequestOperationManager *manager;
}
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation UserLoggedOutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    DDLogDebug(@"userLoggedOutController did load");

    // Do any additional setup after loading the view.
}
-(void)viewWillAppear:(BOOL)animated{
    DDLogDebug(@"view will appear");
    [[WormholeProvider instance]catchNotification:AUWormholeNotificationUserSignIn handler:^(id  _Nullable messageObject) {
        [self dismsissModalView];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeAction:(id)sender {
    [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:@"closeExtension" object:nil]];
}

- (void)dismsissModalView{
//    [self dismissViewControllerAnimated:NO completion:^{
//        [NSNotificationCenter.defaultCenter postNotificationName:@"dismissModalView" object:nil];
//    }];
    [NSNotificationCenter.defaultCenter postNotification:[NSNotification notificationWithName:@"closeExtension" object:nil]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

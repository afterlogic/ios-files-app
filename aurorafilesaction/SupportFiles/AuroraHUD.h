//
//  AuroraHUD.h
//  aurorafiles
//
//  Created by Cheshire on 24.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
@interface AuroraHUD : NSObject

@property (strong, nonatomic) MBProgressHUD *hudView;

+(AuroraHUD *)checkConnectionHUD:(UIViewController *)vc;
+(AuroraHUD *)checkFileExistanceHUD:(UIViewController *)vc;
+(AuroraHUD *)addHUDCheckFileExistanceHUD:(UIViewController *)vc;
+(AuroraHUD *)uploadHUD:(UIView *)view;

- (void)uploadError;
- (void)uploadSuccess;

-(void)hideHUD;
-(void)setHudComplitionHandler:(MBProgressHUDCompletionBlock)handler;
-(void)hideHUDWithDelay:(CGFloat)delay;
@end

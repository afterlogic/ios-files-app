//
//  AuroraHUD.m
//  aurorafiles
//
//  Created by Cheshire on 24.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "AuroraHUD.h"


@interface AuroraHUD ()

@property (strong, nonatomic) UIView *customView;

@end

@implementation AuroraHUD

-(id)init{
    if (self == [super init]) {
        
    }
    return self;
}

+(AuroraHUD *)checkFileExistanceHUD:(UIViewController *)vc{
    AuroraHUD *hud = [AuroraHUD new];
    if (hud) {
        hud.customView = [[UIView alloc]initWithFrame:vc.view.frame];
        [hud.customView setBackgroundColor:[UIColor colorWithRed:0.21 green:0.24 blue:0.25 alpha:0.8]];
        [vc.view addSubview:hud.customView];
        [vc.view bringSubviewToFront:hud.customView];
        hud.hudView = [MBProgressHUD showHUDAddedTo:hud.customView animated:YES];
        hud.hudView.mode = MBProgressHUDModeIndeterminate;
        hud.hudView.label.text = NSLocalizedString(@"Check saved folder existance...", @"");
    }
    return hud;
}

+(AuroraHUD *)checkConnectionHUD:(UIViewController *)vc{
    AuroraHUD *hud = [AuroraHUD new];
    if (hud) {
        hud.customView = [[UIView alloc]initWithFrame:vc.view.frame];
        [hud.customView setBackgroundColor:[UIColor colorWithRed:0.21 green:0.24 blue:0.25 alpha:0.8]];
        [vc.view addSubview:hud.customView];
        [vc.view bringSubviewToFront:hud.customView];
        hud.hudView = [MBProgressHUD showHUDAddedTo:hud.customView animated:YES];
        hud.hudView.mode = MBProgressHUDModeIndeterminate;
        hud.hudView.label.text = NSLocalizedString(@"Check connection...", @"");
    }
    return hud;
}

+(AuroraHUD *)uploadHUD:(UIView *)view{
    AuroraHUD *hud = [AuroraHUD new];
    if (hud) {
        hud.customView = [[UIView alloc]initWithFrame:view.frame];
        [hud.customView setBackgroundColor:[UIColor colorWithRed:0.21 green:0.24 blue:0.25 alpha:0.8]];
        [view addSubview:hud.customView];
        [view bringSubviewToFront:hud.customView];
        hud.hudView = [MBProgressHUD showHUDAddedTo:hud.customView animated:YES];
        hud.hudView.mode = MBProgressHUDModeDeterminate;
    }
    return hud;
}

-(void)showHUD{
    [self.hudView showAnimated:YES];
}

-(void)hideHUD{
    [self.hudView hideAnimated:YES];
    [self.customView removeFromSuperview];
}

-(void)hideHUDWithDelay:(CGFloat)delay{
    [self performSelector:@selector(hideHUD) withObject:self afterDelay:delay];
}

@end

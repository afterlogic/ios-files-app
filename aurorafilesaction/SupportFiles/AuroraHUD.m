 //
//  AuroraHUD.m
//  aurorafiles
//
//  Created by Cheshire on 24.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "AuroraHUD.h"
#import "ErrorProvider.h"


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
        hud.hudView = [MBProgressHUD showHUDAddedTo:hud.customView animated:YES];
        hud.hudView.mode = MBProgressHUDModeIndeterminate;
        hud.hudView.label.text = NSLocalizedString(@"Check saved folder existance...", @"");
    }
    return hud;
}

+(AuroraHUD *)addHUDCheckFileExistanceHUD:(UIViewController *)vc{
    AuroraHUD *hud = [AuroraHUD checkFileExistanceHUD:vc];
    [vc.view addSubview:hud.customView];
    [vc.view bringSubviewToFront:hud.customView];
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

+(void)showError:(NSError *) error view:(UIView *)view{
    
    NSString *errorCode = [NSString stringWithFormat:@"%li",(long)error.code];
    if ([errorCode isEqualToString:@"-999"]) {
        return;
    }
    
    NSString *text = [[AuroraHUD getErrorList] valueForKey:errorCode];
    if(text.length == 0){
        text = error.localizedDescription;
    }

    
    AuroraHUD *hud = [AuroraHUD new];
    if (hud) {
        hud.customView = [[UIView alloc]initWithFrame:view.frame];
        [hud.customView setBackgroundColor:[UIColor colorWithRed:0.21 green:0.24 blue:0.25 alpha:0.8]];
        [view addSubview:hud.customView];
        [view bringSubviewToFront:hud.customView];
        hud.hudView = [MBProgressHUD showHUDAddedTo:hud.customView animated:YES];
        hud.hudView.mode = MBProgressHUDModeIndeterminate;
        hud.hudView.label.text = NSLocalizedString(@"ERROR", @"error popup label");
        hud.hudView.detailsLabel.text = text;
    }
    [hud showHUD];
    [hud hideHUDWithDelay:3.0f];
}


-(void)uploadError{
    if (self.hudView.mode != MBProgressHUDModeCustomView){
        self.hudView.mode = MBProgressHUDModeCustomView;
    }
    self.hudView.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"error"]];
    self.hudView.detailsLabel.text = @"";
    self.hudView.label.text = NSLocalizedString(@"Files uploaded with some errors...", @"");
}

-(void)uploadSuccess{
    if (self.hudView.mode != MBProgressHUDModeCustomView){
        self.hudView.mode = MBProgressHUDModeCustomView;
    }
    self.hudView.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"success"]];
    self.hudView.detailsLabel.text = @"";
    self.hudView.label.text = NSLocalizedString(@"Files succesfully uploaded!", @"");
}

-(void)showHUD{
    [self.hudView showAnimated:YES];
}

-(void)hideHUD{
    [self.hudView hideAnimated:YES];
    [self.customView removeFromSuperview];
}

-(void)setHudComplitionHandler:(MBProgressHUDCompletionBlock)handler{
    self.hudView.completionBlock = handler;
}

-(void)hideHUDWithDelay:(CGFloat)delay{
    [self performSelector:@selector(hideHUD) withObject:self afterDelay:delay];
}

+(NSDictionary *)getErrorList{
    return [[ErrorProvider instance]getErrorList];
}
@end

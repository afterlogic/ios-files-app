//
//  SocialLoginWebPopupViewController.h
//  aurorafiles
//
//  Created by Артем Ковалев on 05.09.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignControllerDelegate.h"

@interface SocialLoginWebPopupViewController : UIViewController
@property (nonatomic, weak) NSURLRequest *authRequest;
@property (weak, nonatomic) id<SocialLoginDelegate> delegate;
@end

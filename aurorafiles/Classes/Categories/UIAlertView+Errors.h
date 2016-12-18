//
//  UIAlertView+Errors.h
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (Errors)
+(void)generatePopupWithError:(NSError *)error forVC:(UIViewController *)vc;
@end

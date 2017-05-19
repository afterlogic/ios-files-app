//
//  UIAlertController+Confirmation.h
//  aurorafiles
//
//  Created by Cheshire on 19.05.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Confirmation)

+ (UIAlertController *)confirmationAlertWithTitle:(NSString *)title message:(NSString *)message confirmHandler:(void(^)())confirmHandler cancelHandler:(void(^)())cancelHandler;

@end

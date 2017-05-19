//
//  UIAlertController+Confirmation.m
//  aurorafiles
//
//  Created by Cheshire on 19.05.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "UIAlertController+Confirmation.h"

@implementation UIAlertController (Confirmation)

+ (UIAlertController *)confirmationAlertWithTitle:(NSString *)title message:(NSString *)message confirmHandler:(void(^)())confirmHandler cancelHandler:(void(^)())cancelHandler{
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:title
                                                                          message:message
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"confirm negative text")
                                                           style:UIAlertActionStyleCancel
                                                         handler:cancelHandler];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"confirm positive text")
                                                            style:UIAlertActionStyleDestructive
                                                          handler:confirmHandler];
    
    [confirmAlert addAction:confirmAction];
    [confirmAlert addAction:cancelAction];
    
    return confirmAlert;
}

@end

//
//  UIAlertView+Errors.m
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "UIAlertView+Errors.h"

@implementation UIAlertView (Errors)

+(UIAlertView *)generatePopupWithError:(NSError *)error forVC:(UIViewController *)vc{
    NSString *errorCode = [NSString stringWithFormat:@"%li",(long)error.code];
    NSString *text = [[UIAlertView getErrorList] valueForKey:errorCode];
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", @"error popup label")
                                                message:text
                                               delegate:nil
                                      cancelButtonTitle:NSLocalizedString(@"OK", @"error popup cancelButton Title")
                                      otherButtonTitles:nil, nil];
    return a;
}

+(NSDictionary *)getErrorList{
    return @{
             @"401":NSLocalizedString(@"The host is not responding. Try connecting again later", @"401 error text"),
             @"4061":NSLocalizedString(@"You have entered an invalid e-mail address. Please try again", @"4061 error text"),
             @"4062":NSLocalizedString(@"Host field should not be empty. Please, enter the host url and try again", @"4062 error text"),
             @"500":NSLocalizedString(@"The e-mail or password you entered is incorrect", @"500 error text")
             };
}

@end

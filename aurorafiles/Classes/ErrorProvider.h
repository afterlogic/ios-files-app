//
//  ErrorProvider.h
//  aurorafiles
//
//  Created by Cheshire on 02.06.17.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//



@interface ErrorProvider : NSObject
@property (nonatomic, weak) UIViewController * currentViewController;

+ (ErrorProvider *)instance;

- (void)generatePopWithError:(NSError *)error controller:(UIViewController *)vc;
- (void)generatePopWithError:(NSError *)error controller:(UIViewController *)vc customCancelAction:(void (^ __nullable)(UIAlertAction *action))handler;

@end

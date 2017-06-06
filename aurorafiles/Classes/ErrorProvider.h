//
//  ErrorProvider.h
//  aurorafiles
//
//  Created by Cheshire on 02.06.17.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//



@interface ErrorProvider : NSObject

+ (ErrorProvider *)instance;

- (void)generatePopWithError:(NSError *)error controller:(UIViewController *)vc;
- (void)generatePopWithError:(NSError *)error controller:(UIViewController *)vc customCancelAction:(void (^ __nullable)(UIAlertAction *cancelAction))handler;
- (void)generatePopWithError:(NSError *)error controller:(UIViewController *)vc customCancelAction:(void (^ __nullable)(UIAlertAction *cancelAction))handler retryAction:(void (^ __nullable)(UIAlertAction *retryAction))retryHandler;

@end

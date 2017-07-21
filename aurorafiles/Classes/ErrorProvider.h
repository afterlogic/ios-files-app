//
//  ErrorProvider.h
//  aurorafiles
//
//  Created by Cheshire on 02.06.17.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//



@interface ErrorProvider : NSObject

+ (ErrorProvider *)instance;

- (BOOL)generatePopWithError:(NSError *)error controller:(UIViewController *)vc;
- (BOOL)generatePopWithError:(NSError *)error controller:(UIViewController *)vc customCancelAction:(void (^ __nullable)(UIAlertAction *cancelAction))handler;
- (BOOL)generatePopWithError:(NSError *)error controller:(UIViewController *)vc customCancelAction:(void (^ __nullable)(UIAlertAction *cancelAction))handler retryAction:(void (^ __nullable)(UIAlertAction *retryAction))retryHandler;
- (NSError *_Nonnull)generateError:(NSString *_Nonnull)errorCode;

- (NSDictionary *_Nonnull)getErrorList;

@end

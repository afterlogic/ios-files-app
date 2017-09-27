//
//  SignControllerDelegate.h
//  aurorafiles
//
//  Created by Артем Ковалев on 06.09.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol SignControllerDelegate <NSObject>

@required
- (void)userWasSignedIn;
- (void)userWasSigneInOffline;
@end

@protocol SocialLoginDelegate <NSObject>

- (void)authToken:(NSString *)token;
- (void)loginError:(NSError *)error;

@end

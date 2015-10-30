//
//  API.h
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface API : NSObject

+ (instancetype) sharedInstance;

- (void)getAppDataCompletionHandler:(void (^)(NSDictionary* data, NSError* error)) handler;

- (void)signInWithEmail:(NSString*)email andPassword:(NSString*)password completion:(void (^)(NSDictionary *data, NSError *error)) handler;

- (void)checkIsAccountAuthorisedWithCompletion:(void (^)(NSDictionary *data, NSError *error)) handler;

- (void)getFilesForFolder:(NSString*)folderName isCorporate:(BOOL)corporate completion:(void (^)(NSDictionary *data)) handler;

- (void)deleteFiles:(NSDictionary*)files isCorporate:(BOOL)corporate completion: (void (^)(NSDictionary* data)) handler;

@end

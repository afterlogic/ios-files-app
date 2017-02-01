//
//  CheckConnectionOperation.m
//  aurorafiles
//
//  Created by Cheshire on 26.01.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "CheckConnectionOperation.h"

@interface CheckConnectionOperation ()

/**
 Completion block to be called once the the request and parsing is completed. Will return the parsed answers or nil.
 */
@property (nonatomic, copy) void (^completion)(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager);
@property (nonatomic, strong) id<ApiProtocol> manager ;

@end

@implementation CheckConnectionOperation

- (instancetype)initWithManager:(id<ApiProtocol>)manager  Completion:(void (^)(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager))completion
{
    self = [super init];
    
    if (self)
    {
        self.completion = completion;
        self.name = @"P7-Check";
        self.manager = manager;
    }
    
    return self;
}

#pragma mark - Start

- (void)start
{
    [super start];
    
    [self.manager checkConnection:^(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager) {
        if (self.completion)
        {
            self.completion(success,error,version,currentManager);
        }
        
        [self finish];
    }];
}

#pragma mark - Cancel

- (void)cancel
{
    [super cancel];
    
    [self finish];
}


@end

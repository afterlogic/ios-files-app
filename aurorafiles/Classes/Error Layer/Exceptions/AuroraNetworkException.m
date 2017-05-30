//
//  AuroraNetworkException.m
//  aurorafiles
//
//  Created by Cheshire on 25.05.17.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//

#import "AuroraNetworkException.h"

 static const NSString * defaultNetworkExceptionName = @"Aurora netwok exception";

@interface AuroraNetworkException()
    @property (nonatomic, weak, readwrite) NSString * userTitle;
    @property (nonatomic, weak, readwrite) NSString * userDescription;
@end

@implementation AuroraNetworkException

- (instancetype)initWithError:(NSError * )error{
    self = [super initWithName:defaultNetworkExceptionName
                        reason:error.localizedDescription
                      userInfo:error.userInfo];
    if (self) {

    }
    return self;
}

+ (AuroraNetworkException *)initWithError:(NSError * )error{
    return [[AuroraNetworkException alloc] initWithError:error];
}

+ (void)raiseWithError:(NSError * )error{
    AuroraNetworkException *exception = [AuroraNetworkException initWithError:error];
    [exception raise];
}

@end

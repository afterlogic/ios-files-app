//
//  AuroraNetworkException.h
//  aurorafiles
//
//  Created by Cheshire on 25.05.17.
//  Copyright (c) 2017 afterlogic. All rights reserved.
//



@interface AuroraNetworkException : NSException

@property (nonatomic, weak, readonly) NSString * userTitle;
@property (nonatomic, weak, readonly) NSString * userDescription;

- (instancetype)initWithError:(NSError * )error;
+ (AuroraNetworkException *)initWithError:(NSError * )error;

+ (void)raiseWithError:(NSError * )error;

@end

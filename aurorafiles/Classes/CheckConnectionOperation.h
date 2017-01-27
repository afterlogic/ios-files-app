//
//  CheckConnectionOperation.h
//  aurorafiles
//
//  Created by Cheshire on 26.01.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "ApiOperation.h"
#import "ApiProtocol.h"

@interface CheckConnectionOperation : ApiOperation

- (instancetype)initWithManager:(id<ApiProtocol>)manager  Completion:(void (^)(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager))completion;
@end

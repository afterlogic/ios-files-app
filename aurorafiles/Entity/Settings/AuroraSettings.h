//
//  AuroraSettings.h
//  aurorafiles
//
//  Created by Артем Ковалев on 02.10.2017.
//  Copyright © 2017 afterlogic. All rights reserved.
//
//

#import <Foundation/Foundation.h>

@interface AuroraSettings : NSObject
@property (nonatomic, copy) NSString *currentAccaunt;
@property (nonatomic, copy) NSString *domain;
@property (nonatomic, copy) NSString *domainScheme;
@property (nonatomic, copy) NSString *firstRun;
@property (nonatomic, copy) NSNumber *isLogedIn;
@property (nonatomic, copy) NSString *lastLoginServerVersion;
@property (nonatomic, copy) NSDictionary *lastUsedFolder;

+ (instancetype)sharedSettings;
- (void)clearAuroraSettings;
@end



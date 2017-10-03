//
//  AuroraSettings.m
//  aurorafiles
//
//  Created by Артем Ковалев on 02.10.2017.
//  Copyright © 2017 afterlogic. All rights reserved.
//
//
#import "AuroraSettings.h"
#import "Settings.h"


@implementation AuroraSettings

+ (instancetype)sharedSettings
{
    static AuroraSettings *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AuroraSettings *tmpSettings = [AuroraSettings loadFromUserDefaults];
        if (tmpSettings != nil){
            sharedInstance = tmpSettings;
        }else{
            sharedInstance = [[AuroraSettings alloc] init];
        }
    });
    return sharedInstance;
}

- (id)init{
    self = [super init];
    if(self){
//        _currentAccaunt = [NSNumber new];
//        _domain = [NSString new];
//        _domainScheme = [NSString new];
//        _firstRun = [NSString new];
//        _lastLoginServerVersion = [NSString new];
        _lastUsedFolder = [NSDictionary new];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder{
    if(self = [super init]){
        self.currentAccaunt = [decoder decodeObjectForKey:@"currentAccaunt"];
        self.domain = [decoder decodeObjectForKey:@"domain"];
        self.domainScheme = [decoder decodeObjectForKey:@"domainScheme"];
        self.firstRun = [decoder decodeObjectForKey:@"firstRun"];
        self.lastLoginServerVersion = [decoder decodeObjectForKey:@"lastLoginServerVersion"];
        self.lastUsedFolder = [decoder decodeObjectForKey:@"lastUsedFolderPath"];
        self.isLogedIn = [decoder decodeObjectForKey:@"isLoggedIn"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.currentAccaunt forKey:@"currentAccaunt"];
    [encoder encodeObject:self.domain forKey:@"domain"];
    [encoder encodeObject:self.domainScheme forKey:@"domainScheme"];
    [encoder encodeObject:self.firstRun forKey:@"firstRun"];
    [encoder encodeObject:self.lastLoginServerVersion forKey:@"lastLoginServerVersion"];
    [encoder encodeObject:self.lastUsedFolder forKey:@"lastUsedFolderPath"];
    [encoder encodeObject:self.isLogedIn forKey:@"isLoggedIn"];
}

-(void)clearAuroraSettings{
    self.currentAccaunt = nil;
    self.domain = nil;
    self.domainScheme = nil;
    self.firstRun = nil;
    self.lastLoginServerVersion = nil;
    self.lastUsedFolder = nil;
    self.isLogedIn = nil;
}

+(AuroraSettings *)loadFromUserDefaults{
    NSData *encodedObject = [[Settings sharedDefaults]objectForKey:auroraSettingsKey];
    NSArray *arrWithSettings = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
    return [arrWithSettings firstObject];
}

@end

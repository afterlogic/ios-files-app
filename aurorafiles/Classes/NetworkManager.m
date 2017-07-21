//
//  NetworkManager.m
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "NetworkManager.h"
#import "P7Manager.h"
#import "CheckConnectionOperation.h"
#import "P8Manager.h"
#import "Settings.h"
#import "NSObject+PerformSelectorWithCallback.h"
#import "AFNetworking.h"

static int const kNUMBER_OF_RETRIES = 6;

@interface NetworkManager(){
    __block int operationCounter;
    __block NSMutableArray *managers;
}

@property (strong, nonatomic) id<ApiProtocol> currentNetworkManager;
@property (strong, nonatomic) NSOperationQueue *checkHostOperations;
@property (nonatomic, strong) Class settings;


@end

@implementation NetworkManager

+ (instancetype)sharedManager{
    static NetworkManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[NetworkManager alloc] init];
    });
    return sharedManager;
}

+ (instancetype)sharedManagerWithSettings:(Class)settingsClass{
    static NetworkManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[NetworkManager alloc] initWithSettings:settingsClass];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        operationCounter = kNUMBER_OF_RETRIES;
        self.checkHostOperations = [[NSOperationQueue alloc]init];
        [self.checkHostOperations setName:@"com.AuroraFilesApp.checkSSLandHostVersion"];
        self.checkHostOperations.maxConcurrentOperationCount = 1;
        _settings = [Settings class];

    }
    return self;
}
- (instancetype)initWithSettings:(Class)settingsClass
{
    self = [super init];
    if (self) {
        operationCounter = kNUMBER_OF_RETRIES;
        self.checkHostOperations = [[NSOperationQueue alloc]init];
        [self.checkHostOperations setName:@"com.AuroraFilesApp.checkSSLandHostVersion"];
        self.checkHostOperations.maxConcurrentOperationCount = 1;
        _settings = settingsClass;
        
    }
    return self;
}

-(id<ApiProtocol>)getNetworkManager{
    if ([[self.settings lastLoginServerVersion]isEqualToString:@"P8"]) {
        self.currentNetworkManager = [[P8Manager alloc]init];
    }else if ([[self.settings lastLoginServerVersion]isEqualToString:@"P7"]) {
        self.currentNetworkManager = [[P7Manager alloc]init];
    }
    return self.currentNetworkManager;
}

-(void)prepareForCheck{
    if (!managers) {
        managers = [[NSMutableArray alloc]init];
        [managers addObjectsFromArray:@[[P8Manager new],[P8Manager new],[P7Manager new],[P7Manager new]]];
    }
}

-(void)checkDomainVersionAndSSLConnection:(void(^)(NSString *domainVersion, NSString *correctHostURL))handler{
    [self checkConnectionUsingSerialQueue:handler];
}



-(void)updateDomain{
    NSURL * url = [NSURL URLWithString:[self.settings domain]];
    NSString *resourceSpec = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
    NSString *scheme = @"";
    if ([[url scheme] isEqualToString:@"http://"] || ![url scheme]) {
        scheme = @"https://";
    }else{
        scheme = @"http://";
    }
    [self.settings setDomainScheme:scheme];
    NSString *domain = [NSString stringWithFormat:@"%@%@",[self.settings domainScheme],resourceSpec];
    DDLogDebug(@"⚠️ current used domain is -> %@",domain);
}
//

//- (void)saveDomainVersion:(NSString *)domainVersion{
//    //    NSString * scheme = [[NSURL URLWithString:[self.settings domain]] scheme];
//    //    NSString * urlString = [NSString stringWithFormat:@"%@%@",scheme ? @"" : @"https://",[self.settings domain]];
//    //    [self.settings setDomain:urlString];
//    if (domainVersion) {
//        if (![[self.settings lastLoginServerVersion] isEqualToString:domainVersion]) {
//            [[StorageManager sharedManager]deleteAllObjects:@"Folder"];
//        }
//        [self.settings setLastLoginServerVersion:domainVersion];
////        self.networkManager = [NetworkManager getNetworkManager];
//    }
//}


#pragma mark - Debug Methods

-(void)checkConnectionUsingSerialQueue:(void(^)(NSString *domainVersion, NSString *correctHostURL))handler{
    

    CheckConnectionOperation *checkAPIv8operation = [[CheckConnectionOperation alloc]initWithManager:[P8Manager new] Completion:^(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager) {
        if (success) {
            handler(version,[self.settings domain]);
            DDLogDebug(@"%@ %@ %@", [NSNumber numberWithBool:success],error,version);
        }
        
        if (error || !success) {
            handler(nil,nil);
            DDLogDebug(@"%@ %@ %@", [NSNumber numberWithBool:success],error,version);
        }
    }];
    
    CheckConnectionOperation *checkAPIv7operation = [[CheckConnectionOperation alloc]initWithManager:[P7Manager new] Completion:^(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager) {
        if (success) {
            handler(version,[self.settings domain]);
            DDLogDebug(@"%@ %@ %@", [NSNumber numberWithBool:success],error,version);
        }
        
        if (error || !success) {
            DDLogDebug(@"%@ %@ %@", [NSNumber numberWithBool:success],error,version);
            if ([[self.checkHostOperations operations]containsObject:checkAPIv8operation]){
                
            }else{
                [self.checkHostOperations addOperation:checkAPIv8operation];
            }
        }
    }];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    manager.securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy.validatesDomainName = NO;
    [manager setResponseSerializer:[AFJSONResponseSerializer serializer]];
    
    NSURL * url = [NSURL URLWithString:[self.settings domain]];
    NSString *resourceSpec = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
    NSString *scheme = @"";
    if (![url scheme]) {
        scheme = @"http://";
    }
    NSString *domain = [NSString stringWithFormat:@"%@%@",scheme,resourceSpec];
    
//    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    [manager HEAD:domain parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation) {
        NSURL *responseURL = [operation.response URL];
        NSString *responseScheme = [NSString stringWithFormat:@"%@://",[responseURL scheme]];
        [self.settings setDomainScheme:responseScheme];
        DDLogDebug(@"%@",[self.settings domainScheme]);
        [self.checkHostOperations addOperation:checkAPIv7operation];
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        NSDictionary *headers = [operation.response allHeaderFields];
        DDLogDebug(@"%@ %@",headers,error);
        handler(nil,nil);
    }];
}


@end

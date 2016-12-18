//
//  NetworkManager.m
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "NetworkManager.h"
#import "P7Manager.h"
#import "P8Manager.h"
#import "Settings.h"
#import "NSObject+PerformSelectorWithCallback.h"

static int const kNUMBER_OF_RETRIES = 6;

@interface NetworkManager(){
    __block int operationCounter;
    __block NSMutableArray *managers;
}

@property (strong, nonatomic) id<ApiProtocol> currentNetworkManager;


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

- (instancetype)init
{
    self = [super init];
    if (self) {
        operationCounter = kNUMBER_OF_RETRIES;
    }
    return self;
}

-(id<ApiProtocol>)getNetworkManager{
    if (!self.currentNetworkManager) {
        if ([[Settings version]isEqualToString:@"P8"]) {
            self.currentNetworkManager = [[P8Manager alloc]init];
        }else if ([[Settings version]isEqualToString:@"P7"]) {
            self.currentNetworkManager = [[P7Manager alloc]init];
        }
    }
    return self.currentNetworkManager;
}

-(void)checkDomainVersionAndSSLConnection:(void(^)(NSString *domainVersion, NSString *correctHostURL))handler{
    
    id<ApiProtocol>sameManager;
    
    if (!managers) {
        managers = [[NSMutableArray alloc]init];
        [managers addObjectsFromArray:@[[P8Manager new],[P8Manager new],[P7Manager new],[P7Manager new]]];
    }
    
    if (managers.count == 0) {
        managers = nil;
        handler(nil,nil);
        return;
    }
    
    if (managers.count >= 1) {
        sameManager = [managers lastObject];
    }
    
    [sameManager checkConnection:^(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                self.currentNetworkManager = sameManager;
                handler(version,[Settings domain]);
            }else{
                if (managers.count > 0) {
                    [self updateDomain];
                    [self checkDomainVersionAndSSLConnection:^(NSString *domainVersion, NSString *correctHostURL) {
                        if (domainVersion && correctHostURL) {
                            handler(domainVersion,correctHostURL);
                            return;
                        }
                        if(managers.count == 0) {
                            managers = nil;
                            handler(domainVersion,correctHostURL);
                            return;
                        }
                    }];
                }else{
                    managers = nil;
                    handler(nil,nil);
                }
            }
        });
    }];
    
    if (managers.count > 0) {
        [managers removeLastObject];
    }

}

-(void)checkConnection:(void(^)(NSString *domainVersion, NSString *correctHostURL))handler forManager:(id<ApiProtocol>)currentManaget{
    
//    P8Manager *theP8Manager = [[P8Manager alloc]init];
//    P7Manager *theP7Manager = [[P7Manager alloc]init];
//    
//    
//    [theP8Manager checkConnection:^(BOOL success, NSError *error) {
//        if (success) {
//            NSString *domainVersion = @"P8";
//            handler(domainVersion,[Settings domain]);
//            return;
//        }
//        if (!success || error) {
//            [theP7Manager checkConnection:^(BOOL success, NSError *error) {
//                if (success) {
//                    NSString *domainVersion = @"P7";
//                    handler(domainVersion,[Settings domain]);
//                    return;
//                }
//                if (!success || error) {
//                    if (operationCounter > 0) {
//                        operationCounter -=1;
//                        [self updateDomain];
//                        [self checkConnection:^(NSString *domainVersion, NSString *correctHostURL) {}];
//                    }else{
//                        handler(nil,nil);
//                        return;
//                    }
//                }
//            }];
//        }
//    }];
    
//        __weak NetworkManager * weakSelf = self;
//
//        [currentManaget checkConnection:^(BOOL success, NSError *error, NSString *version, id<ApiProtocol> currentManager) {
//            NetworkManager *strongSelf = weakSelf;
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                if (success) {
//                        handler(version,[Settings domain]);
//                }else{
//
//                    [strongSelf updateDomain];
//
//                    [strongSelf checkDomainVersionAndSSLConnection:^(NSString *domainVersion, NSString *correctHostURL) {
//
//                    }];
//                    
//                }
//            });
//        }];
}

//- (void)checkSSLConnection:(void (^)(NSString *))handler{
//    NSLog(@"⚠️ start checking SSL");
//    __block NSError *p8Error = [NSError new];
//    operationCounter += 1;
//    if (operationCounter >= kNUMBER_OF_RETRIES) {
//        operationCounter = 0;
//        handler(nil);
//    }else{
//        
//        [[ApiP8 coreModule] pingHostWithCompletion:^(BOOL isP8, NSError *error){
//            p8Error = error;
//            if (isP8){
//                [self saveDomainVersion:@"P8"];
//                handler([Settings domain]);
//                operationCounter = 0;
//                return;
//            }else if(!isP8 || error){
//                [[ApiP7 sharedInstance]getAppDataCompletionHandler:^(NSDictionary *data, NSError *error) {
//                    if (error && p8Error) {
//                        [self updateDomain];
//                        [self checkSSLConnection:^(NSString *domain) {
//                            handler(domain);
//                        }];
//                    }
//                    if(data){
//                        [self saveDomainVersion:@"P7"];
//                        handler([Settings domain]);
//                        operationCounter = 0;
//                        return;
//                    }
//                }];
//            }else{
//                [self saveDomainVersion:nil];
//                handler([Settings domain]);
//                operationCounter = 0;
//                return;
//            }
//        }];
//    }
//}
//


-(void)updateDomain{
    NSURL * url = [NSURL URLWithString:[Settings domain]];
    NSString *resourceSpec = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
    NSString *scheme = @"";
    if ([[url scheme] isEqualToString:@"http://"] || ![url scheme]) {
        scheme = @"https://";
    }else{
        scheme = @"http://";
    }
    [Settings setDomainScheme:scheme];
    NSString *domain = [NSString stringWithFormat:@"%@%@",[Settings domainScheme],resourceSpec];
    NSLog(@"⚠️ current used domain is -> %@",domain);
}
//

//- (void)saveDomainVersion:(NSString *)domainVersion{
//    //    NSString * scheme = [[NSURL URLWithString:[Settings domain]] scheme];
//    //    NSString * urlString = [NSString stringWithFormat:@"%@%@",scheme ? @"" : @"https://",[Settings domain]];
//    //    [Settings setDomain:urlString];
//    if (domainVersion) {
//        if (![[Settings version] isEqualToString:domainVersion]) {
//            [[StorageManager sharedManager]deleteAllObjects:@"Folder"];
//        }
//        [Settings setLastLoginServerVersion:domainVersion];
////        self.networkManager = [NetworkManager getNetworkManager];
//    }
//}



@end

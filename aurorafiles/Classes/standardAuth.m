//
//  standardAuth.m
//  aurorafiles
//
//  Created by Cheshire on 18.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "standardAuth.h"
#import "Folder.h"
#import "AFNetworking.h"
#import "Settings.h"
#import "NSURLRequest+requestGenerator.h"

@interface standardAuth(){
    AFHTTPRequestOperationManager *manager;
}

@end

@implementation standardAuth 

static NSString *moduleName = @"StandardAuth";
static NSString *methodLogin = @"Login";

-(id)init{
    self = [super init ];
    if(self){
        manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
    }
    return self;
}

+ (instancetype) sharedInstance
{
    static standardAuth *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[standardAuth alloc] init];
    });
    return sharedInstance;
}

- (void)signInWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(NSDictionary *data, NSError *error))handler{
    
//    NSURLRequest * request = [self requestWithDictionary:@{@"Action":signInAction,@"Email":email, @"IncPassword":password}];
    NSURLRequest *request = [NSURLRequest p8RequestWithDictionary:@{@"Module":moduleName,
                                                                    @"Method":methodLogin,
                                                                    @"Parameters":@{@"Login":email,
                                                                                    @"Password":password,
                                                                                    @"SignMe":@"true"}}];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSError *error;
            NSData *data = [NSData new];
            if ([responseObject isKindOfClass:[NSData class]]) {
                data = responseObject;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([json isKindOfClass:[NSDictionary class]])
            {
                if ([[json valueForKey:@"Result"] isKindOfClass:[NSArray class]])
                {
                    NSString *token = @"";
                    for (NSDictionary *dict in [json valueForKey:@"Result"]) {
                        if ([[dict valueForKey:@"Method"]isEqualToString:methodLogin] && [[dict valueForKey:@"Module"]isEqualToString:moduleName] ) {
                            if ([[dict valueForKey:@"Result"] isKindOfClass:[NSDictionary class]]) {
                                token = [dict valueForKeyPath:@"Result.AuthToken"];
                            }
                        }
                    }
                    NSNumber * accountID = [json objectForKey:@"AuthenticatedUserId"];
                    if (accountID)
                    {
                        [Settings setCurrentAccount:accountID];
                    }
                    if (token.length)
                    {
                        [Settings setAuthToken:token];
                        error = nil;
                    }
                    else
                    {
                        error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{}];
                    }
                }
                else
                {
                    error = [[NSError alloc] initWithDomain:@"com.afterlogic" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The username or password you entered is incorrect", @"")}];
                }
            }
            handler(json,error);
        });
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"HTTP Request failed: %@", error);
            handler(nil,error);
        });
    }];
    
    [manager.operationQueue addOperation:operation];

}

@end

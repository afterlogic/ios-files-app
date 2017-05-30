//
//  FileOperationsProvider.m
//  aurorafiles
//
//  Created by Cheshire on 28.11.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "FileOperationsProvider.h"
#import "Settings.h"
#import "ApiProtocol.h"
#import "NetworkManager.h"
#import "UIAlertView+Errors.h"

@interface FileOperationsProvider(){
    
}

@property (nonatomic, strong) id<ApiProtocol> networkManager;
@end

@implementation FileOperationsProvider

+ (instancetype)sharedProvider {
    static FileOperationsProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FileOperationsProvider alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self)
    {
//        self.networkManager = [[NetworkManager sharedManager]getNetworkManager];
    }
    return self;
}

- (void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager getFilesFromHostForFolder:folderPath withType:type completion:^(NSArray *items, NSError *error) {
        if (error){
            [UIAlertView generatePopupWithError:error];
            complitionHandler(@[]);
        }else{
            complitionHandler(items);
        }
    }];
}

- (void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success))handler{
    [self setupNetworkManager];
    [self.networkManager renameFileFromName:name toName:newName type:type atPath:path isLink:isLink completion:^(BOOL success, NSError *error) {
        if (error){
            [UIAlertView generatePopupWithError:error];
            handler(NO);
        }else{
            handler(success);
        }
    }];
}

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *result))handler{
    [self setupNetworkManager];
    [self.networkManager renameFolderFromName:name toName:newName type:type atPath:path isLink:isLink completion:^(NSDictionary *result, NSError *error) {
        if(error){
            [UIAlertView generatePopupWithError:error];
            handler(nil);
        }else{
            handler(result);
        }
    }];
}

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager createFolderWithName:name isCorporate:corporate andPath:path completion:^(BOOL success, NSError *error) {
        if(error){
            [UIAlertView generatePopupWithError:error];
            complitionHandler(NO);
        }else{
            complitionHandler(success);
        }
    }];
}

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(BOOL))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager deleteFile:folder isCorporate:corporate completion:^(BOOL success, NSError *error) {
        if(error){
            [UIAlertView generatePopupWithError:error];
            complitionHandler(NO);
        }else{
            complitionHandler(success);
        }
    }];
}

- (void)deleteFiles:(NSArray<Folder *>*)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager deleteFiles:files isCorporate:corporate completion:^(BOOL success, NSError *error) {
        if(error){
            [UIAlertView generatePopupWithError:error];
            complitionHandler(NO);
        }else{
            complitionHandler(success);
        }
    }];
}

//MARK: важная функция для работы экстеншена
- (void)checkItemExistanceOnServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager checkItemExistenceOnServerByName:name path:path type:type completion:^(BOOL exist, NSError *error) {
        if(error){
            [UIAlertView generatePopupWithError:error];
            complitionHandler(NO);
        }else{
            complitionHandler(exist);
        }
    }];
    
}

- (void)stopDownloadigThumbForFile:(NSString *)fileName{
    [self setupNetworkManager];
    [self.networkManager stopFileThumb:fileName];
}

- (void)setupNetworkManager{
//    if (!self.networkManager) {
        self.networkManager = [[NetworkManager sharedManager]getNetworkManager];
//    }
}

- (void)clearNetworkManager{
    self.networkManager = nil;
}

@end

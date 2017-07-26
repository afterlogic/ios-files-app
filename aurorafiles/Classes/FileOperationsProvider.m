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

- (void)getFilesFromHostForFolder:(NSString *)folderPath withType:(NSString *)type completion:(void (^)(NSArray *items, NSError *error))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager getFilesFromHostForFolder:folderPath withType:type completion:^(NSArray *items, NSError *error) {
        if (error){
            complitionHandler(@[],error);
        }else{
            complitionHandler(items,nil);
        }
    }];
}

- (void)findFilesUsingPattern:(NSString *)searchPattern withType:(NSString *)type completion:(void (^)(NSArray *items, NSError *error))complitionHandler{
    [self.networkManager findFilesWithPattern:searchPattern type:type completion:^(NSArray *items, NSError *error) {
        if (error){
            complitionHandler(@[],error);
        }else{
            complitionHandler(items,nil);
        }
    }];
}

- (void)renameFileFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(BOOL success, NSError *error))handler{
    [self setupNetworkManager];
    [self.networkManager renameFileFromName:name toName:newName type:type atPath:path isLink:isLink completion:^(BOOL success, NSError *error) {
        if (error){
//            [[ErrorProvider instance] generatePopWithError:error controller:nil];
            handler(NO,error);
        }else{
            handler(success,nil);
        }
    }];
}

- (void)renameFolderFromName:(NSString *)name toName:(NSString *)newName type:(NSString *)type atPath:(NSString *)path isLink:(BOOL)isLink completion:(void (^)(NSDictionary *result, NSError *error))handler{
    [self setupNetworkManager];
    [self.networkManager renameFolderFromName:name toName:newName type:type atPath:path isLink:isLink completion:^(NSDictionary *result, NSError *error) {
        if(error){
//            [[ErrorProvider instance] generatePopWithError:error controller:nil];
            handler(nil,error);
        }else{
            handler(result,nil);
        }
    }];
}

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager createFolderWithName:name isCorporate:corporate andPath:path completion:^(BOOL success, NSError *error) {
        if(error){
//            [[ErrorProvider instance] generatePopWithError:error controller:nil];
            complitionHandler(NO,error);
        }else{
            complitionHandler(success,nil);
        }
    }];
}

- (void)deleteFile:(Folder *)folder isCorporate:(BOOL)corporate completion:(void (^)(BOOL, NSError *error))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager deleteFile:folder isCorporate:corporate completion:^(BOOL success, NSError *error) {
        if(error){
//            [[ErrorProvider instance] generatePopWithError:error controller:nil];
            complitionHandler(NO,error);
        }else{
            complitionHandler(success,nil);
        }
    }];
}

- (void)deleteFiles:(NSArray<Folder *> *)files isCorporate:(BOOL)corporate completion:(void (^)(BOOL, NSError *error))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager deleteFiles:files isCorporate:corporate completion:^(BOOL success, NSError *error) {
        if(error){
//            [[ErrorProvider instance] generatePopWithError:error controller:nil];
            complitionHandler(NO,error);
        }else{
            complitionHandler(success,nil);
        }
    }];
}

//MARK: важная функция для работы экстеншена
- (void)checkItemExistanceOnServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist, NSError *error))complitionHandler{
    [self setupNetworkManager];
    [self.networkManager checkItemExistenceOnServerByName:name path:path type:type completion:^(BOOL exist, NSError *error) {
        if(error){
//            [[ErrorProvider instance] generatePopWithError:error controller:nil];
            complitionHandler(NO,error);
        }else{
            complitionHandler(exist,nil);
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

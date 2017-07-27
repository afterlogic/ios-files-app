//
//  StorageManager.m
//  aurorafiles
//
//  Created by Michael Akopyants on 15/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "StorageManager.h"
#import "SessionProvider.h"
#import "Settings.h"

#import "IDataBaseProtocol.h"
#import "IFileOperationsProtocol.h"

#import "Folder.h"
#import "MBProgressHUD.h"


@interface StorageManager()
@property (readwrite, strong, nonatomic) id<IDataBaseProtocol>DBProvider;
@property (strong, nonatomic) id<IFileOperationsProtocol>fileOperationsProvider;
@property (nonatomic, strong) NSOperationQueue *filesOperationsQueue;
@end

@implementation StorageManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.filesOperationsQueue = [[NSOperationQueue alloc]init];
        [self.filesOperationsQueue setName:@"com.AuroraFiles.FilesOperationsQueue"];
    }

    return self;
}



+ (instancetype)sharedManager
{
    static StorageManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[StorageManager alloc] init];
    });
    return sharedInstance;
}

- (void)setupDBProvider:(id<IDataBaseProtocol>)provider{
    self.DBProvider = provider;
}

- (void)setupFileOperationsProvider:(id<IFileOperationsProtocol>)provider{
    self.fileOperationsProvider = provider;
}

#pragma mark -

- (void)renameOperation:(Folder *)file withNewName:(NSString *)newName withCompletion:(void (^)(Folder *updatedFile, NSError *error))complitionHandler{
    if ([file.isFolder boolValue]){
        [self renameFolder:file toNewName:newName withCompletion:complitionHandler];
    }else{
        [self renameToFile:file newName:newName withCompletion:complitionHandler];
    }
}

- (void)renameToFile:(Folder *)file newName:(NSString *)newName withCompletion:(void (^)(Folder *updatedFile, NSError *error))complitionHandler{
    NSString * oldName = file.name;
    NSString * type = file.type;
    NSString * parentPath = file.parentPath ? file.parentPath : @"";
    bool isLink = file.isLink.boolValue;
    
    NSString *fileNewName = newName;
//    NSString *ex = [oldName pathExtension];
//    NSString *newNameExtension = [newName pathExtension];
//    if ([newNameExtension length] == 0)
//    {
//        NSString *tmpName = [newName stringByAppendingPathExtension:ex];
//        fileNewName = tmpName;
//    }
//    else
//    {
//        fileNewName = newName;
//    }

    if (!file)
    {
        NSError *error = [NSError new];
        complitionHandler(nil,error);
        return ;
    }
    
    [self.fileOperationsProvider renameFileFromName:oldName toName:fileNewName type:type atPath:parentPath isLink:isLink completion:^(BOOL success, NSError *error) {
        if(error){
            complitionHandler(nil,error);
            return;
        }
        if (success) {
            [self.DBProvider saveWithBlock:^(NSManagedObjectContext *context) {
                if (file.isDownloaded){
                    [Folder renameLocalFile:file newName:fileNewName];
                }
                file.name = fileNewName;
                file.identifier = fileNewName;
                file.downloadedName = fileNewName;
                NSString *newFullPath = @"";
                NSMutableArray *path = [file.fullpath componentsSeparatedByString:@"/"].mutableCopy;
                [path replaceObjectAtIndex:[path indexOfObject:[path lastObject]] withObject:fileNewName];
                newFullPath = [path componentsJoinedByString:@"/"];
                file.fullpath = newFullPath;

                NSString *primaryKey = [NSString stringWithFormat:@"%@:%@",type,newFullPath];
                file.prKey = primaryKey;

                complitionHandler(file,nil);
            }];
        }else{
            complitionHandler(NO,nil);
        }

    }];
}

- (void)renameFolder:(Folder *)folder toNewName:(NSString *)newName withCompletion:(void (^)(Folder *, NSError *error))handler{
    if (folder.isFault) {
        return;
    }
    NSString * oldName = folder.name;
    NSString * oldPath = folder.fullpath;
    NSString * type = folder.type;
    NSString * parentPath = folder.parentPath;
    BOOL isLink = folder.isLink.boolValue;
    
    
    [self.fileOperationsProvider renameFolderFromName:oldName toName:newName type:type atPath:parentPath ? parentPath :@"" isLink:isLink completion:^(NSDictionary *result, NSError *error) {
        if(error){
            handler(nil,error);
            return;
        }

        if (result) {
//            [self.DBProvider saveWithBlock:^(NSManagedObjectContext *context) {
                NSManagedObjectContext *context = self.DBProvider.defaultMOC;
                folder.name = newName;
                NSMutableDictionary * itemRefWithPrKey = result.mutableCopy;
                NSString *primaryKey = [NSString stringWithFormat:@"%@:%@",result[@"Type"],result[@"FullPath"]];
                [itemRefWithPrKey setObject:primaryKey forKey:@"primaryKey"];
                
                Folder *object = [FEMDeserializer objectFromRepresentation:itemRefWithPrKey mapping:folder.isP8 ? [Folder P8RenameMapping] : [Folder renameMapping] context:context];

                NSSortDescriptor *title = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@", folder.type, oldPath];
                NSArray *fetched = [Folder fetchFoldersInContext:context descriptors:@[title] predicate:predicate];
                for (Folder *childFolder in fetched) {
                    childFolder.parentPath = object.fullpath;
                }
                
                NSManagedObjectID *folderID = [folder objectID];
                if ([context objectWithID:folderID]) {
                    [self.DBProvider deleteObject:folder fromContext:context];
                }
                NSManagedObjectContext *folderContext = folder.managedObjectContext;
                DDLogDebug(@"%@",folderContext);
                [context save:nil];
                dispatch_async(dispatch_get_main_queue(), ^() {
                    if (handler) {
                        handler(object,nil);
                    }
                });
//            }];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^(){
                if (handler) {
                    handler(nil,nil);
                }
            });
        }
    }];
}

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success, NSError *error))complitionHandler{
    [self.fileOperationsProvider  createFolderWithName:name isCorporate:corporate andPath:path completion:^(BOOL success, NSError *error) {
        complitionHandler(success,error);
    }];
}

- (void)checkItemExistanceonServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist, NSError *error))complitionHandler{
    [self.fileOperationsProvider   checkItemExistanceOnServerByName:name path:path type:type completion:^(BOOL exist, NSError *error) {
        complitionHandler(exist,error);
    }];
}

- (void)deleteItem:(Folder *)item controller:(UIViewController *)controller isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess, NSError *error))handler{
    
    NSString *confirmTitle = [NSString stringWithFormat:@"%@ %@ ?",NSLocalizedString(@"Delete", @"delete confirmation title text"),item.name];
    NSString *confirmMessage = NSLocalizedString(@"You cannot undo this action.", @"delete confirmation message text");
    void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
        [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
        [self.fileOperationsProvider deleteFile:item isCorporate:corporate completion:^(BOOL success, NSError *error) {
            if(!error){
                [self deleteItem:item];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:controller.view animated:YES];
                });
                [[ErrorProvider instance]generatePopWithError:error
                                                   controller:controller
                                           customCancelAction:nil
                                                  retryAction:actionBlock];
            }
            handler(success,error);
        }];
    };
    
    UIAlertController *confirmController = [UIAlertController confirmationAlertWithTitle:confirmTitle
                                                                                 message:confirmMessage
                                                                          confirmHandler:actionBlock
                                                                           cancelHandler:nil];
    [controller presentViewController:confirmController animated:YES completion:nil];
}

#pragma mark -

- (void)stopGettingFileThumb:(NSString *)fileName{
    [self.fileOperationsProvider stopDownloadigThumbForFile:fileName];
}

- (void)updateFilesWithType:(NSString *)type forFolder:(Folder *)folder withCompletion:(void (^)(NSInteger *itemsCount, NSError *error))handler{
    if (folder.isFault) {
        handler(0,nil);
        return;
    }

    NSString * folderPath = folder ? folder.fullpath : @"";
        [[SessionProvider sharedManager] checkUserAuthorization:^(BOOL authorised, BOOL offline,BOOL isP8, NSError *error){
            if(error){
                handler(0,error);
                return;
            }
            if (authorised) {
                [self.fileOperationsProvider getFilesFromHostForFolder:folderPath withType:type completion:^(NSArray *items, NSError *error) {
                    if (items) {
                        [self saveItemsIntoDB:items forFolder:folder WithType:type isP8:isP8];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        if (handler) {
                            handler(items.count,nil);
                        }
                    });
                }];
            }else{
                handler(0,nil);
            }
        }];
}

- (void)searchFilesUsingPattern:(NSString *)pattern type:(NSString *) type handler:(void(^)(NSInteger itemsCount, NSError *error ))complitionHandler{
    [self.fileOperationsProvider findFilesUsingPattern:pattern withType:type completion:^(NSArray *items, NSError *error) {
        if(error){
            complitionHandler(0, error);
        }else{
            __block NSMutableArray *searchItems = [NSMutableArray new];
            [self.DBProvider saveWithBlock:^(NSManagedObjectContext *context) {
                for (NSDictionary *itemRef in items ) {
                        Folder *searchFolder = [Folder createSearchFolderFromRepresentation:itemRef type:[[Settings lastLoginServerVersion] isEqualToString:@"P8"] InContext:self.DBProvider.defaultMOC];
                        [searchItems addObject:searchFolder];
                }
            } completionBlock:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    complitionHandler(items.count, nil);
                });
            }];
        }
    }];
}

- (void)saveItemsIntoDB:(NSArray *)items forFolder:(Folder *)folder WithType:(NSString*)type isP8:(BOOL)isP8{
    __block NSArray *blockItems = items.copy;
    [self.DBProvider saveWithBlock:^(NSManagedObjectContext *context) {
        [self prepareItemsForSave:blockItems forFolder:folder WithType:type usingContext:context isP8:isP8];
    }];
}

- (void)prepareItemsForSave:(NSArray *)items forFolder:(Folder *)folder WithType:(NSString*)type usingContext:(NSManagedObjectContext *)context isP8:(BOOL) isP8{
    NSString * folderPath = folder ? folder.fullpath : @"";
    if (items.count)
    {
        NSMutableArray * existIds = [NSMutableArray new];
        for (NSDictionary * itemRef in items)
        {
            Folder * childFolder = [Folder createFolderFromRepresentation:itemRef type:isP8 parrentPath:folderPath InContext:context];
            [existIds addObject:childFolder.prKey];
        }
        
        NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        NSString *currentFolderFullPath = folder ? folder.fullpath : @"";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@" NOT (prKey IN %@) AND parentPath = %@ AND type=%@",existIds,currentFolderFullPath,type];
        NSArray * oldFolders = [Folder fetchFoldersInContext:context descriptors:descriptors predicate:predicate];

        for (Folder* fold in oldFolders)
        {
            if (!fold.isDownloaded.boolValue)
            {
                [self deleteOldThumbsAndViews:fold];
                [self.DBProvider deleteObject:fold fromContext:context];
            }
            else
            {
                fold.wasDeleted = @YES;
            }
        }
    }
    else{
        NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentPath = %@ AND type=%@",folder.fullpath,type];
        NSArray * oldFolders = [Folder fetchFoldersInContext:context descriptors:descriptors predicate:predicate];

        for (Folder* fold in oldFolders)
        {
            if (!fold.isDownloaded.boolValue)
            {
                [self deleteOldThumbsAndViews:fold];
                [self.DBProvider deleteObject:fold fromContext:context];
            }
            else
            {
                fold.wasDeleted = @YES;
            }
        }
    }
}

- (void)saveLastUsedFolder:(NSDictionary *)folderSimpleRef{
    [Settings saveLastUsedFolder:folderSimpleRef];
}

- (void)getLastUsedFolderWithHandler:(void (^)(NSDictionary *result, NSError *error))complition{
    NSDictionary *savedFolderRef = [Settings getLastUsedFolder];
    NSArray * lastUsedFolders;
    if ([savedFolderRef isKindOfClass:[NSArray class]]) {
        [Settings saveLastUsedFolder:nil];
        lastUsedFolders = @[];
        NSError *error = [NSError errorWithDomain:@"com.afterlogic"
                                             code:-999
                                         userInfo:nil];
        complition (nil,error);
        return;
    }
    if (savedFolderRef.count == 0) {
        [Settings saveLastUsedFolder:nil];
        lastUsedFolders = @[];
        NSError *error = [NSError errorWithDomain:@"com.afterlogic"
                                             code:-999
                                         userInfo:nil];
        complition (nil,error);
        return;
    }

    [self checkItemExistanceonServerByName:savedFolderRef[@"Name"] path:savedFolderRef[@"ParrentPath"] type:savedFolderRef[@"Type"] completion:^(BOOL exist, NSError *error) {
        if (error) {
            complition(nil,error);
            return;
        }
        if(exist){
            complition(savedFolderRef,nil);
        }else{
            complition(nil,nil);
        }
    }];
}


#pragma mark -
//- (Folder *)getFolderWithName:(NSString *)name type:(NSString *)type fullPath:(NSString *)path{
//    return [self getObjectWithName:name type:type fullPath:path isFolder:YES];
//}

//- (Folder *)getObjectWithName:(NSString *)name type:(NSString *)type fullPath:(NSString *)path isFolder:(BOOL) isFolder{
//    NSManagedObjectContext* context = [self.DBProvider defaultMOC];
//   __block NSArray * items;
//    NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFolder = %@ AND fullpath = %@ AND name = %@ AND type = %@",[NSNumber numberWithBool:isFolder],path,name,type];
//    items = [Folder fetchFoldersInContext:context descriptors:descriptors predicate:predicate];
//    return [items lastObject];
//}



#pragma mark -
//- (void)removeDuplicatesForItems:(NSArray *)items{
//    for (NSDictionary *folder in items) {
//        NSSortDescriptor *isFolder = [[NSSortDescriptor alloc]
//                                      initWithKey:@"isFolder" ascending:NO];
//        NSSortDescriptor *title = [[NSSortDescriptor alloc]initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
//
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@ AND wasDeleted= NO",folder[@"Id"]];
//
//        NSMutableArray * result = [Folder fetchFoldersInContext:[self.DBProvider defaultMOC] descriptors:@[isFolder, title] predicate:predicate].mutableCopy;;
//        if (result.count > 1) {
//           result = [self removeDuplicatesFromOneItemFetch:result withParentPath:folder[@"Path"]].mutableCopy;
//        }
//        DDLogDebug(@"%@",result);
//    }
//};

//- (NSArray *)removeDuplicatesFromOneItemFetch:(NSMutableArray *)fetchResult  withParentPath:(NSString *)parentPath{
//    [self.DBProvider saveWithBlock:^(NSManagedObjectContext *context) {
//        Folder *originalFolder;
//        for (Folder *item in fetchResult) {
//            if ([item.parentPath isEqualToString:parentPath]) {
//                originalFolder = item;
//            }
//        }
//        for (Folder *item in fetchResult) {
//            if (![item isEqual:originalFolder]) {
//                [self.DBProvider deleteObject:item fromContext:[self.DBProvider defaultMOC]];
//            }
//        }
//    }];
//    return fetchResult;
//}

- (void)deleteItem:(Folder *)item{
    [self.DBProvider saveWithBlock:^(NSManagedObjectContext *context) {
        item.wasDeleted = @YES;
    }];
}

#pragma mark - Files Stack

- (void)deleteOldThumbsAndViews:(Folder *)folder{
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *fullThumbURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"thumb_%@",folder.name]];
    NSURL *fullURL = [documentsDirectoryURL URLByAppendingPathComponent:folder.name];
    if ([fileManager fileExistsAtPath:fullThumbURL.path]) {
        [fileManager removeItemAtPath:fullThumbURL.path error:NULL];
    }
    if ([fileManager fileExistsAtPath:fullURL.path]) {
        [fileManager removeItemAtPath:fullURL.path error:NULL];
    }
}

- (void)deleteAllObjects: (NSString *) entityDescription{
    NSManagedObjectContext* context = [self.DBProvider defaultMOC];
    [context performBlockAndWait:^ {

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    
    for (NSManagedObject *managedObject in items) {
        [self.DBProvider deleteObject:managedObject fromContext:context];
        DDLogDebug(@"%@ object deleted",entityDescription);
    }
        [context save:&error];
    if (error) {
        DDLogError(@"Error deleting %@ - error:%@",entityDescription,error);
    }}];
}

- (void)clear{
    [self deleteAllObjects:@"Folder"];
    [self.fileOperationsProvider clearNetworkManager];
}

#pragma mark - Remove Files

- (void)removeSavedFilesForItem:(Folder *)item{
    NSString *filePath = [Folder getExistedFile:item];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:NULL];
    }
}


@end

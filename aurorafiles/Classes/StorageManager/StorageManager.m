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


@interface StorageManager()
@property (readwrite, strong, nonatomic) id<IDataBaseProtocol>DBProvider;
@property (strong, nonatomic) id<IFileOperationsProtocol>fileOperationsProvider;
@property (nonatomic, strong) NSOperationQueue *filesOperationsQueue;
@end

@implementation StorageManager

+ (instancetype)sharedManager
{
    static StorageManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[StorageManager alloc] init];
    });
    return sharedInstance;
}



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

- (void)setupDBProvider:(id<IDataBaseProtocol>)provider{
    self.DBProvider = provider;
}

- (void)setupFileOperationsProvider:(id<IFileOperationsProtocol>)provider{
    self.fileOperationsProvider = provider;
}

#pragma mark -

- (void)renameOperation:(Folder *)file withNewName:(NSString *)newName withCompletion:(void (^)(Folder* updatedFile))complitionHandler{
    if ([file.isFolder boolValue]){
        [self renameFolder:file toNewName:newName withCompletion:complitionHandler];
    }else{
        [self renameToFile:file newName:newName withCompletion:complitionHandler];
    }
}

- (void)renameToFile:(Folder *)file newName:(NSString *)newName withCompletion:(void (^)(Folder* updatedFile))complitionHandler{
    NSString * oldName = file.name;
    NSString * type = file.type;
    NSString * parentPath = file.parentPath ? file.parentPath : @"";
    bool isLink = file.isLink.boolValue;
    NSString *fileNewName;
    NSString *ex = [oldName pathExtension];
    NSString *newNameExtension = [newName pathExtension];
    if ([newNameExtension length] == 0)
    {
        NSString *tmpName = [newName stringByAppendingPathExtension:ex];
        fileNewName = tmpName;
    }
    else
    {
        fileNewName = newName;
    }

    if (!file)
    {
        complitionHandler(nil);
        return ;
    }
    
    [self.fileOperationsProvider renameFileFromName:oldName toName:fileNewName type:type atPath:parentPath isLink:isLink completion:^(BOOL success) {
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

                complitionHandler(file);
            }];
        }else{
            complitionHandler(nil);
        }

    }];
}

- (void)renameFolder:(Folder *) folder toNewName:(NSString *)newName withCompletion:(void (^)(Folder *))handler{
    if (folder.isFault) {
        return;
    }
    NSString * oldName = folder.name;
    NSString * oldPath = folder.fullpath;
    NSString * type = folder.type;
    NSString * parentPath = folder.parentPath;
    BOOL isLink = folder.isLink.boolValue;
    
    
    [self.fileOperationsProvider renameFolderFromName:oldName toName:newName type:type atPath:parentPath ? parentPath :@"" isLink:isLink completion:^(NSDictionary *result) {
        if (result) {
            [self.DBProvider saveWithBlock:^(NSManagedObjectContext *context) {
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
                
                dispatch_async(dispatch_get_main_queue(), ^() {
                    if (handler) {
                        handler(object);
                    }
                });
            }];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^(){
                if (handler) {
                    handler(nil);
                }
            });
        }
    }];
}

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success))complitionHandler{
    [self.fileOperationsProvider  createFolderWithName:name isCorporate:corporate andPath:path completion:^(BOOL success) {
        complitionHandler(success);
    }];
}

- (void)checkItemExistanceonServerByName:(NSString *)name path:(NSString *)path type:(NSString *)type completion:(void (^)(BOOL exist))complitionHandler{
    [self.fileOperationsProvider   checkItemExistanceOnServerByName:name path:path type:type completion:^(BOOL exist) {
        complitionHandler(exist);
    }];
}

- (void)deleteItem:(Folder *)item controller:(UIViewController *)controller isCorporate:(BOOL)corporate completion:(void (^)(BOOL succsess))handler{
    
    NSString *confirmTitle = [NSString stringWithFormat:@"%@ %@ ?",NSLocalizedString(@"Delete", @"delete confirmation title text"),item.name];
    NSString *confirmMessage = NSLocalizedString(@"You cannot undo this action.", @"delete confirmation message text");
    UIAlertController *confirmController = [UIAlertController confirmationAlertWithTitle:confirmTitle
                                                                                 message:confirmMessage
                                                                          confirmHandler:^{
                                                                              [self deleteItem:item];
                                                                              [self.fileOperationsProvider deleteFile:item isCorporate:corporate completion:^(BOOL success) {
                                                                                  handler(success);
                                                                              }];
                                                                          }
                                                                           cancelHandler:nil];
    [controller presentViewController:confirmController animated:YES completion:nil];
}

#pragma mark -

- (void)stopGettingFileThumb:(NSString *)fileName{
    [self.fileOperationsProvider stopDownloadigThumbForFile:fileName];
}

- (void)updateFilesWithType:(NSString *)type forFolder:(Folder *)folder withCompletion:(void (^)(NSInteger *itemsCount))handler{
    if (folder.isFault) {
        handler(0);
        return;
    }
    NSString * folderPath = folder ? folder.fullpath : @"";
//    NSBlockOperation *filesUpdateOperation = [NSBlockOperation blockOperationWithBlock:^{
        [[SessionProvider sharedManager] checkUserAuthorization:^(BOOL authorised, BOOL offline,BOOL isP8){
            if (authorised) {
                [self.fileOperationsProvider getFilesFromHostForFolder:folderPath withType:type completion:^(NSArray *items) {
                    if (items) {
                        [self saveItemsIntoDB:items forFolder:folder WithType:type isP8:isP8];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        if (handler) {
                            handler(items.count);
                        }
                    });
                }];
            }else{
                
            }
        }];
//    }];
//    [self.filesOperationsQueue addOperation:filesUpdateOperation];

}

- (void)saveItemsIntoDB:(NSArray *)items forFolder:(Folder *)folder WithType:(NSString*)type isP8:(BOOL)isP8{
//    [self removeDuplicatesForItems:items];
    __block NSArray *blockItems = items.copy;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0),^{
    [self.DBProvider saveWithBlock:^(NSManagedObjectContext *context) {
        [self prepareItemsForSave:blockItems forFolder:folder WithType:type usingContext:context isP8:isP8];
    }];
//    });

}

- (void)prepareItemsForSave:(NSArray *)items forFolder:(Folder *)folder WithType:(NSString*)type usingContext:(NSManagedObjectContext *)context isP8:(BOOL) isP8{
//    if (!context) {
//        context = [self.DBProvider operationsMOC];
//    }
//    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:items];
//    items = [orderedSet array];
//    NSMutableArray * existItems = [NSMutableArray new];
    NSString * folderPath = folder ? folder.fullpath : @"";
    if (items.count)
    {
        NSMutableArray * existIds = [NSMutableArray new];
        for (NSDictionary * itemRef in items)
        {
            Folder * childFolder = [Folder createFolderFromRepresentation:itemRef type:isP8 parrentPath:folderPath InContext:context];
            [existIds addObject:childFolder.prKey];
//            if ([childFolder.thumb boolValue] && ![childFolder.isFolder boolValue] && ![childFolder.isLink boolValue]) {
//                [existItems addObject:childFolder];
//            }
        }
        
        NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        NSString *currentFolderFullPath = folder ? folder.fullpath : @"";
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@" NOT (name IN %@) AND parentPath = %@ AND type=%@",existIds,currentFolderFullPath,type];
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

- (void)getLastUsedFolderWithHandler:(void(^)(NSDictionary *result))complition{
    NSDictionary *savedFolderRef = [Settings getLastUsedFolder];
    NSArray * lastUsedFolders;
    if ([savedFolderRef isKindOfClass:[NSArray class]]) {
        [Settings saveLastUsedFolder:nil];
        lastUsedFolders = @[];
        complition (nil);
        return;
    }
    if (savedFolderRef.count == 0) {
        [Settings saveLastUsedFolder:nil];
        lastUsedFolders = @[];
        complition (nil);
        return;
    }

    [self checkItemExistanceonServerByName:savedFolderRef[@"Name"] path:savedFolderRef[@"ParrentPath"] type:savedFolderRef[@"Type"] completion:^(BOOL exist) {
        if(exist){
            complition(savedFolderRef);
        }else{
            complition(nil);
        }
    }];
}

- (NSString *)generateParentPath:(NSString *)itemFullpath{
    NSMutableArray *pathParts = [itemFullpath componentsSeparatedByString:@"/"].mutableCopy;
    DDLogDebug(@"%@",pathParts);
    [pathParts removeObject:[pathParts lastObject]];
    if (pathParts.count == 1) {
        return [pathParts lastObject];
    }
    return [pathParts componentsJoinedByString:@"/"];
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

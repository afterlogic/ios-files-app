//
//  StorageManager.m
//  aurorafiles
//
//  Created by Michael Akopyants on 15/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "StorageManager.h"
#import "API.h"
#import "SessionProvider.h"
#import "ApiP8.h"
#import "Settings.h"
#import <MagicalRecord/MagicalRecord.h>
@interface StorageManager()
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation StorageManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (instancetype)sharedManager
{
    static StorageManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[StorageManager alloc] init];
    });
    return sharedInstance;
}

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.makopyants.aurorafiles" in the application's documents directory.
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.afterlogic.aurorafiles"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"aurorafiles" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter]
         addObserverForName:NSManagedObjectContextDidSaveNotification
         object:nil
         queue:nil
         usingBlock:^(NSNotification* note) {
             NSManagedObjectContext *moc = self.managedObjectContext;
             if (note.object != moc)
             {
                 [moc performBlock:^(){
                     [moc mergeChangesFromContextDidSaveNotification:note];
                 }];
             }
             
         }];
    }
    
    return self;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"aurorafiles.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:[NSNumber numberWithBool:YES],NSInferMappingModelAutomaticallyOption:[NSNumber numberWithBool:YES]} error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    return _persistentStoreCoordinator;
}

#pragma mark - Setup CoreData Stack

- (void)initCoreData{
    _managedObjectModel = [self managedObjectModel];
    _persistentStoreCoordinator = [self persistentStoreCoordinator];
    _managedObjectContext = [self managedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}
    
- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}
    
- (Folder *)objectWithURI:(NSURL *)uri
{
    NSManagedObjectID *objectID = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:uri];
    
    if (!objectID)
    {
        return nil;
    }
    
    Folder *objectForID = [self.managedObjectContext objectWithID:objectID];
    if (![objectForID isFault])
    {
        return objectForID;
    }
    
//    NSFetchRequest *request =[[NSFetchRequest alloc] init];
//    [request setEntity:[objectID entity]];
    
    // Equivalent to
//     NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF = %@", objectForID];
    NSPredicate *predicate =[NSComparisonPredicate
     predicateWithLeftExpression:
     [NSExpression expressionForEvaluatedObject]
     rightExpression:
     [NSExpression expressionForConstantValue:objectForID]
     modifier:NSDirectPredicateModifier
     type:NSEqualToPredicateOperatorType
     options:0];
//    [request setPredicate:predicate];
    
    NSArray *results = [Folder MR_findAllWithPredicate:predicate];
    if ([results count] > 0 )
    {
        return [results objectAtIndex:0];
    }
    
    return nil;
}

#pragma mark -
- (void)renameFile:(Folder *)file toNewName:(NSString *)newName withCompletion:(void (^)(Folder* updatedFile))complitionHandler
{
    NSString * oldName = file.name;
    NSString * type = file.type;
    NSString * parentPath = file.parentPath ? file.parentPath : @"";
    bool isLink = file.isLink.boolValue;
    NSString *fileNewName;
    NSString * ex = [oldName pathExtension];
    if ([ex length])
    {
        fileNewName = [newName stringByAppendingPathExtension:[oldName pathExtension]];
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
    
    if ([[Settings version] isEqualToString:@"P8"]) {
        [[ApiP8 filesModule]renameFolderFromName:oldName toName:fileNewName type:type atPath:parentPath isLink:isLink completion:^(BOOL success) {
            if (success) {
                [self.managedObjectContext performBlockAndWait:^{
                    file.name = fileNewName;
                    file.identifier = fileNewName;
                    NSString *newFullPath = @"";
                    NSMutableArray *path = [file.fullpath componentsSeparatedByString:@"/"].mutableCopy;
                    [path replaceObjectAtIndex:[path indexOfObject:[path lastObject]] withObject:fileNewName];
                    newFullPath = [path componentsJoinedByString:@"/"];
                    file.fullpath = newFullPath;
                    complitionHandler(file);
                }];
                NSError *error = [NSError new];
                if ([self.managedObjectContext save:&error]) {
                }
            }else{
                complitionHandler(nil);
            }
        }];
    }else{
        [[API sharedInstance] renameFolderFromName:oldName toName:fileNewName isCorporate:[type isEqualToString:@"corporate"] atPath:parentPath isLink:isLink completion:^(NSDictionary* handler) {
            if ([[handler objectForKey:@"Result"]boolValue]) {
                [self.managedObjectContext performBlockAndWait:^{
                    file.name = fileNewName;
                    file.identifier = fileNewName;
                    NSString *newFullPath = @"";
                    NSMutableArray *path = [file.fullpath componentsSeparatedByString:@"/"].mutableCopy;
                    [path replaceObjectAtIndex:[path indexOfObject:[path lastObject]] withObject:fileNewName];
                    newFullPath = [path componentsJoinedByString:@"/"];
                    file.fullpath = newFullPath;
                    complitionHandler(file);
                }];
                NSError *error = [NSError new];
                if ([self.managedObjectContext save:&error]) {
                }
            }else{
                complitionHandler(nil);
            }
        }];
    }
    
}

- (void)renameFolder:(Folder *) folder toNewName:(NSString *)newName withCompletion:(void (^)(Folder *))handler
{
    if (folder.isFault) {
        return;
    }
    NSString * oldName = folder.name;
    NSString * oldPath = folder.fullpath;
    NSString * type = folder.type;
    NSString * parentPath = folder.parentPath;
    BOOL isLink = folder.isLink.boolValue;
    
        if ([[Settings version] isEqualToString:@"P8"]) {
            [[ApiP8 filesModule]renameFolderFromName:oldName toName:newName type:type atPath:parentPath ? parentPath : @"" isLink:isLink  completion:^(BOOL success) {
                if (success) {
                    [self.managedObjectContext performBlockAndWait:^{
                        folder.name = newName;
                        NSManagedObjectContext * folderContext = folder.managedObjectContext;
                        NSFetchRequest *updatedFileRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
                        NSSortDescriptor *title = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                        [updatedFileRequest setSortDescriptors:@[title]];
                        updatedFileRequest.predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND name = %@",folder.type, folder.parentPath,oldName];
                        NSError * error = nil;
                        NSArray * fetched = [folderContext executeFetchRequest:updatedFileRequest error:&error];
                        NSString *newFullPath = @"";
                        Folder *fold = [fetched lastObject];
                        fold.name = newName;
                        fold.identifier = newName;
                        NSMutableArray *path = [fold.fullpath componentsSeparatedByString:@"/"].mutableCopy;
                        [path replaceObjectAtIndex:[path indexOfObject:[path lastObject]] withObject:newName];
                        newFullPath = [path componentsJoinedByString:@"/"];
                        fold.fullpath = newFullPath;
                        
                        
                        NSFetchRequest * fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
                        title = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                        [fetchRequest setSortDescriptors:@[title]];
                        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@",folder.type, oldPath];
                        fetched = [folderContext executeFetchRequest:fetchRequest error:&error];
                        for(Folder * f in fetched)
                        {
                            f.parentPath = newFullPath;
                            NSLog(@"%@",f);
                        }
                        if (error)
                        {
                            NSLog(@"%@",[error userInfo]);
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            if (handler) {
                                handler(fold);
                            }
                        });
                    }];
                    NSError *error = [NSError new];
                    if ([self.managedObjectContext save:&error]) {
                        
                    }
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        if (handler) {
                            handler(nil);
                        }
                    });
                }
            }];
        }else{
            [[API sharedInstance] renameFolderFromName:oldName toName:newName isCorporate:[type isEqualToString:@"corporate"] atPath:parentPath ? parentPath: @"" isLink:isLink  completion:^(NSDictionary* result) {
                if ([[result objectForKey:@"Result"]boolValue]){
                    [[API sharedInstance] getFolderInfoForName:newName path:parentPath ? parentPath : @"" type:type completion:^(NSDictionary * result) {
                    if ([[result objectForKey:@"Result"] isKindOfClass:[NSDictionary class]])
                    {
                        [self.managedObjectContext performBlockAndWait:^{
                            folder.name = newName;
                            NSManagedObjectContext* context = [self managedObjectContext];
                            Folder * object = [FEMDeserializer objectFromRepresentation:[result objectForKey:@"Result"] mapping:[Folder renameMapping] context:context];
                            NSFetchRequest * fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
                            NSSortDescriptor *title = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                            [fetchRequest setSortDescriptors:@[title]];
                            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@",folder.type, oldPath];
                            NSError * error = nil;
                            NSArray * fetched = [context executeFetchRequest:fetchRequest error:&error];
                            for(Folder * childFolder in fetched){
                                childFolder.parentPath = object.fullpath;
                            }
                            [folder MR_deleteEntityInContext:context];
//                            dispatch_async(dispatch_get_main_queue(), ^(){
                            if (handler) {
                                handler(object);
                            }
//                            });
                        }];
                        NSError *error = [NSError new];
                        if ([self.managedObjectContext save:&error]) {
                            NSLog(@"folder %@ renamed successfuly",oldName);
                        }
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            if (handler) {
                                handler(nil);
                            }
                        });
                    }
                    
                }];
                }
                else{
                    if (handler) {
                        handler(nil);
                    }
                }
            }];
        }
}

- (void)createFolderWithName:(NSString *)name isCorporate:(BOOL)corporate andPath:(NSString *)path completion:(void (^)(BOOL success))complitionHandler{
    if ([[Settings version] isEqualToString:@"P8"]) {
        [[ApiP8 filesModule]createFolderWithName:name isCorporate:corporate andPath:path completion:^(BOOL result) {
            if (result) {
                complitionHandler(YES);
            }
        }];
    }else{
        [[API sharedInstance] createFolderWithName:name isCorporate:corporate andPath:path ? path : @"" completion:^(NSDictionary * result){
            if ([[result objectForKey:@"Result"]boolValue]) {
                complitionHandler(YES);
            }
        }];
    }

}

- (void)getItemInfoForName:(NSString *)name path:(NSString *)path corporate:(NSString *)type completion:(void (^)(Folder *result))complitionHandler{
    if ([[Settings version] isEqualToString:@"P8"]) {
        [[ApiP8 filesModule]getFileInfoForName:name path:path corporate:type completion:^(NSDictionary *result) {
            if(result){
                Folder * existedItem = [self findObjectByItemRef:result];
                if (!existedItem) {
                    existedItem = [Folder MR_createEntity];
                    existedItem = [FEMDeserializer fillObject:existedItem fromRepresentation:result mapping: [[Settings version] isEqualToString:@"P8"] ? [Folder P8DefaultMapping]:[Folder defaultMapping]];
                    existedItem.toRemove = [NSNumber numberWithBool:NO];
                    existedItem.isP8 = [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]];
                    existedItem.parentPath = path;
                }
                complitionHandler(existedItem);
            }
        }];
    }else{
        [[SessionProvider sharedManager]authroizeEmail:[Settings domain] withPassword:[Settings password] completion:^(BOOL authorized, NSError *error) {
                [[API sharedInstance] getFolderInfoForName:name path:path type:type completion:^(NSDictionary *result) {
                    if (![[result valueForKey:@"Result"]boolValue]) {
                        complitionHandler(nil);
                    }else{
                        Folder * existedItem = [self findObjectByItemRef:result];
                        if (!existedItem) {
                            existedItem = [Folder MR_createEntity];
                            existedItem = [FEMDeserializer fillObject:existedItem fromRepresentation:result mapping: [[Settings version] isEqualToString:@"P8"] ? [Folder P8DefaultMapping]:[Folder defaultMapping]];
                            existedItem.toRemove = [NSNumber numberWithBool:NO];
                            existedItem.isP8 = [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]];
                            existedItem.parentPath = path;
                        }
                        complitionHandler(existedItem);
                    }
                }];
//            }
        }];
    }
}

#pragma mark -

- (void)updateFileThumbnail:(Folder *)file type:(NSString*)type context:(NSManagedObjectContext *) context complition:(void (^)(UIImage* thumbnail))handler{
    NSString * filepathPath = file ? file.fullpath : @"";
    NSMutableArray *pathArr = [filepathPath componentsSeparatedByString:@"/"].mutableCopy;
    [pathArr removeObject:[pathArr lastObject]];
    if (!context) {
        context = self.managedObjectContext;
    }
    [context performBlockAndWait:^ {
        [[ApiP8 filesModule]getFileThumbnail:file type:type path:[pathArr componentsJoinedByString:@"/"] withCompletion:^(NSString *thumbnail) {
            if (thumbnail) {
                NSError * error = nil;
                NSData *data;
                UIImage *image;
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([thumbnail length] && [fileManager fileExistsAtPath:thumbnail]) {
                    data= [[NSData alloc]initWithContentsOfFile:thumbnail];
                    file.thumbnailLink = thumbnail;
                    image = [UIImage imageWithData:data];
                    [self saveContext];
                }else{
                    handler (nil);
                    return;
                }

                
                if (error)
                {
                    NSLog(@"%@",[error userInfo]);
                    handler (nil);
                    return;
                }
                
                handler(image);
                return ;
            }
            handler (nil);
        }];
    }];
}

- (void)stopGettingFileThumb:(NSString *)fileName{
    [[ApiP8 filesModule]stopFileThumb:fileName];
}

- (void)updateFilesWithType:(NSString*)type forFolder:(Folder*)folder withCompletion:(void (^)())handler
{
    NSString * folderPath = folder ? folder.fullpath : @"";
        [[SessionProvider sharedManager] checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline,BOOL isP8){
            if (isP8 && authorised) {
                NSString * path = folderPath;
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
                    [[ApiP8 filesModule]getFilesForFolder:path withType:type completion:^(NSArray *items){
                        NSArray * filesItems = [self saveItems:items forFolder:folder WithType:type usingContext:localContext isP8:isP8];
                            [self removeChildDuplicatesForFolder:folder];
                        if (filesItems.count>0) {
                            [[ApiP8 filesModule]getThumbnailsForFiles:filesItems withCompletion:^(bool success) {
                                if (success) {
                                    dispatch_async(dispatch_get_main_queue(), ^(){
                                        if (handler) {
                                            handler();
                                        }
                                    });
                                }
                            }];
                        }
                        handler();
                    }];
                }completion:^(BOOL contextDidSave, NSError * _Nullable error) {
                    if (!error && contextDidSave) {
                        [self saveContext];
                    };
                }];
            }else{
                if (authorised)
                {
                    NSString * path = folderPath;
                    [[API sharedInstance] getFilesForFolder:path withType:type completion:^(NSDictionary * result) {
                        NSArray * items;
                        if (result && [result isKindOfClass:[NSDictionary class]] && [[result objectForKey:@"Result"] isKindOfClass:[NSDictionary class]])
                        {
                            items = [[[result objectForKey:@"Result"] objectForKey:@"Items"] isKindOfClass:[NSArray class]] ? [[result objectForKey:@"Result"] objectForKey:@"Items"] : @[];
                        }
                        else
                        {
                            items = @[];
                        }
                        [self.managedObjectContext performBlockAndWait:^{
                            [self saveItems:items forFolder:folder WithType:type usingContext:self.managedObjectContext isP8:isP8];
                            [self removeDuplicatesForItems:items];
                            NSError *error = [NSError new];
                            [self.managedObjectContext save:&error];
                        }];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            if (handler) {
                                handler();
                            }
                            
                        });
                    }];
                    
                }
            }
        }];
}

- (NSArray *)saveItems:(NSArray *)items forFolder:(Folder *)folder WithType:(NSString*)type usingContext:(NSManagedObjectContext *)context isP8:(BOOL) isP8{
    if (!context) {
        context = [[StorageManager sharedManager]managedObjectContext];
    }
    NSMutableArray * existItems = [NSMutableArray new];
    NSString * folderPath = folder ? folder.fullpath : @"";
    if (items.count)
    {
        NSError * error = nil;
        NSMutableArray * existIds = [[NSMutableArray alloc] init];
        for (NSDictionary * itemRef in items)
        {
            
            Folder * existedItem = [self findObjectByItemRef:itemRef];
            if (!existedItem || existedItem.isFault) {
                existedItem = [Folder MR_createEntityInContext:context];
                existedItem = [FEMDeserializer fillObject:existedItem fromRepresentation:itemRef mapping: isP8 ? [Folder P8DefaultMapping]:[Folder defaultMapping]];
                existedItem.toRemove = [NSNumber numberWithBool:NO];
                existedItem.isP8 = [NSNumber numberWithBool:isP8];
                if (folder)
                {
                    existedItem.parentPath = folderPath;
                }
            }
            if ([existedItem.thumb boolValue] && ![existedItem.isFolder boolValue] && ![existedItem.isLink boolValue]) {
                [existItems addObject:existedItem];
            }
            [existIds addObject:existedItem.name];
        }
        
        NSFetchRequest * fetchOldAudiosRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchOldAudiosRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        fetchOldAudiosRequest.predicate = [NSPredicate predicateWithFormat:@"NOT name in (%@) AND parentPath = %@ AND type=%@",existIds,folder.fullpath,type];
        NSArray * oldFolders = [self.managedObjectContext executeFetchRequest:fetchOldAudiosRequest error:&error];
        
        for (Folder* fold in oldFolders)
        {
            if (!fold.isDownloaded.boolValue)
            {
                [self deleteOldThumbsAndViews:fold];
                [fold MR_deleteEntityInContext:context];
            }
            else
            {
                fold.wasDeleted = @YES;
            }
            
        }
        if (error)
        {
            NSLog(@"%@",[error userInfo]);
        }
    }else{
        NSFetchRequest * fetchOldAudiosRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchOldAudiosRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        fetchOldAudiosRequest.predicate = [NSPredicate predicateWithFormat:@"parentPath = %@ AND type=%@",folder.fullpath,type];
        NSError * error = nil;
        NSArray * oldFolders = [self.managedObjectContext executeFetchRequest:fetchOldAudiosRequest error:&error];
        
        for (Folder* fold in oldFolders)
        {
            if (!fold.isDownloaded.boolValue)
            {
                [self deleteOldThumbsAndViews:fold];
                [fold MR_deleteEntityInContext:context];
            }
            else
            {
                fold.wasDeleted = @YES;
            }
            
        }
        if (error)
        {
            NSLog(@"%@",[error userInfo]);
        }
    }
    return existItems;
}

- (void)saveLastUsedFolder:(Folder *)folder{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        NSError *error = [NSError new];
        NSFetchRequest * fetchLastUsedFolder = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchLastUsedFolder.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        fetchLastUsedFolder.predicate = [NSPredicate predicateWithFormat:@"isFolder = YES AND isLastUsedUploadFolder = YES"];
        NSArray * lastUsedFolders = [localContext executeFetchRequest:fetchLastUsedFolder error:&error];
        for (Folder *item in lastUsedFolders) {
            item.isLastUsedUploadFolder = [NSNumber numberWithBool:NO];
        }
        
        if (folder){
            folder.isLastUsedUploadFolder = [NSNumber numberWithBool:YES];
        }
        
        NSDictionary *folderDict = [FEMSerializer serializeObject:folder usingMapping: folder.isP8 ? [Folder P8DefaultMapping]:[Folder defaultMapping]];
        [Settings saveLastUsedFolder:folderDict];
    }];
}

- (void)getLastUsedFolderWithHandler:(void(^)(Folder *result))complition{
    Folder *savedFolder;
    NSManagedObjectContext* context = self.managedObjectContext;
    NSDictionary *savedFolderRef = [Settings getLastUsedFolder];
    NSArray * lastUsedFolders;
    if ([savedFolderRef isKindOfClass:[NSArray class]]) {
        lastUsedFolders = @[];
        complition (nil);
    }
    NSError * error = nil;
    NSFetchRequest * fetchLastUsedFolder = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
    fetchLastUsedFolder.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    fetchLastUsedFolder.predicate = [NSPredicate predicateWithFormat:@"isFolder = YES AND isLastUsedUploadFolder = YES AND name = %@ AND fullpath = %@",savedFolderRef[@"Name"],savedFolderRef[@"FullPath"]];
    lastUsedFolders = [context executeFetchRequest:fetchLastUsedFolder error:&error];
    NSString* parentPath = [self generateParentPath:savedFolderRef[@"FullPath"]];
    if (lastUsedFolders.count == 0) {
        [[StorageManager sharedManager]getItemInfoForName:savedFolderRef[@"Name"] path:parentPath corporate:savedFolderRef[@"Type"] completion:^(Folder *result) {
            if(result){
                complition(result);
            }
        }];
    }else{
        savedFolder = [lastUsedFolders lastObject];
        complition(savedFolder);
    }
}

- (NSString *)generateParentPath:(NSString *)itemFullpath{
    NSMutableArray *pathParts = [itemFullpath componentsSeparatedByString:@"/"].mutableCopy;
    NSLog(@"%@",pathParts);
    [pathParts removeObject:[pathParts lastObject]];
    if (pathParts.count == 1) {
        return [pathParts lastObject];
    }
    return [pathParts componentsJoinedByString:@"/"];
}

- (Folder *)getFolderWithName:(NSString *)name type:(NSString *)type fullPath:(NSString *)path{
    return [self getObjectWithName:name type:type fullPath:path isFolder:YES];
}

- (Folder *)getObjectWithName:(NSString *)name type:(NSString *)type fullPath:(NSString *)path isFolder:(BOOL) isFolder{
    NSManagedObjectContext* context = self.managedObjectContext;
   __block NSArray * items;
    NSError * error = nil;
    NSFetchRequest * fetchItem = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
    fetchItem.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    fetchItem.predicate = [NSPredicate predicateWithFormat:@"isFolder = %@ AND fullpath = %@ AND name = %@ AND type = %@",[NSNumber numberWithBool:isFolder],path,name,type];
    items = [context executeFetchRequest:fetchItem error:&error];
    return [items lastObject];
}

- (Folder *)findObjectByItemRef:(NSDictionary *)itemRef{
    NSFetchRequest *fReq = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
    fReq.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    fReq.predicate = [NSPredicate predicateWithFormat:@"identifier = %@ AND fullpath = %@ AND contentType = %@ AND type = %@ AND name = %@",itemRef[@"Id"],itemRef[@"FullPath"],itemRef[@"ContentType"],itemRef[@"Type"],itemRef[@"Name"]];
    NSError * error = nil;
    NSMutableArray * result = [[[StorageManager sharedManager]managedObjectContext]executeFetchRequest:fReq error:&error].mutableCopy;
    NSArray* cleanedResult  = [self removeDuplicatesFromOneItemFetch:result withParentPath:itemRef[@"Path"]];
    return cleanedResult.lastObject;
}

-(void)removeDuplicatesForItems:(NSArray *)items{
    for (NSDictionary *folder in items) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription
                                       entityForName:@"Folder" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *isFolder = [[NSSortDescriptor alloc]
                                      initWithKey:@"isFolder" ascending:NO];
        NSSortDescriptor *title = [[NSSortDescriptor alloc]initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        [fetchRequest setSortDescriptors:@[isFolder, title]];
        
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier = %@ AND wasDeleted= NO",folder[@"Id"]];
        NSError * error = nil;
        NSMutableArray * result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error].mutableCopy;
        if (result.count > 1) {
           result = [self removeDuplicatesFromOneItemFetch:result withParentPath:folder[@"Path"]].mutableCopy;
        }
        NSLog(@"%@",result);
    }
};

-(NSArray *)removeDuplicatesFromOneItemFetch:(NSMutableArray *)fetchResult  withParentPath:(NSString *)parentPath{
    [self.managedObjectContext performBlockAndWait:^{
        Folder *originalFolder;
        for (Folder *item in fetchResult) {
            if ([item.parentPath isEqualToString:parentPath]) {
                originalFolder = item;
            }
        }
        for (Folder *item in fetchResult) {
            if (![item isEqual:originalFolder]) {
                [item MR_deleteEntityInContext:self.managedObjectContext];
            }
        }
    }];
    NSError * error = [NSError new];
    [self.managedObjectContext save:&error];
    return fetchResult;
}

- (void)deleteItem:(Folder *)item{
    [self.managedObjectContext performBlockAndWait:^{
        item.wasDeleted = @YES;
    }];
    NSError *error = [NSError new];
    [self.managedObjectContext save:&error];
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

- (void)deleteAllObjects: (NSString *) entityDescription  {
    NSManagedObjectContext* context = self.managedObjectContext;
     [context performBlockAndWait:^ {

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    
    for (NSManagedObject *managedObject in items) {
        [context deleteObject:managedObject];
        NSLog(@"%@ object deleted",entityDescription);
    }
         [context save:&error];
         [[StorageManager sharedManager]saveContext];
    if (error) {
        NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }}];
    
}

#pragma mark - Remove Files

- (void)removeSavedFilesForItem:(Folder *)item
{
    NSString *filePath = [[ApiP8 filesModule]getExistedFile:item];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:NULL];
    }
}


@end

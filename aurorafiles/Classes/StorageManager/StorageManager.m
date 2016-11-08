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

- (void)renameFolder:(Folder *) folder toNewName:(NSString *)newName withCompletion:(void (^)(Folder *))handler
{
    
    NSString * oldName = folder.name;
    NSString * oldPath = folder.fullpath;
    NSString * type = folder.type;
    NSString * parentPath = folder.parentPath;
    folder.name = newName;
    if ([[Settings version] isEqualToString:@"P8"]) {
        [[ApiP8 filesModule]renameFolderFromName:oldName toName:newName type:folder.type atPath:folder.parentPath ? folder.parentPath : @"" isLink:folder.isLink.boolValue  completion:^(BOOL success) {
            if (success) {
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


                [folderContext save:&error];
                if (error)
                {
                    NSLog(@"%@",[error userInfo]);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(){
                    if (handler) {
                        handler(fold);
                    }
                });

            }else{
                dispatch_async(dispatch_get_main_queue(), ^(){
                    if (handler) {
                        handler(nil);
                    }
                });
            }
        }];
    }else{
        [[API sharedInstance] renameFolderFromName:oldName toName:newName isCorporate:[folder.type isEqualToString:@"corporate"] atPath:folder.parentPath ? folder.parentPath : @"" isLink:folder.isLink.boolValue  completion:^(NSDictionary* result) {
            NSManagedObjectContext * folderContext = folder.managedObjectContext;
            [folderContext deleteObject:folder];
            NSError * error;
            [folderContext save:&error];
            if (error)
            {
                NSLog(@"%@",[error userInfo]);
            }
            [[API sharedInstance] getFolderInfoForName:newName path:parentPath ? parentPath : @"" type:type completion:^(NSDictionary * result) {
                if ([[result objectForKey:@"Result"] isKindOfClass:[NSDictionary class]])
                {
                    NSManagedObjectContext* context = [self managedObjectContext];
                    
                    Folder * object = [FEMDeserializer objectFromRepresentation:[result objectForKey:@"Result"] mapping:[Folder renameMapping] context:context];
                    NSFetchRequest * fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
                    NSSortDescriptor *title = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
                    [fetchRequest setSortDescriptors:@[title]];
                    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@",folder.type, oldPath];
                    NSError * error = nil;
                    NSArray * fetched = [context executeFetchRequest:fetchRequest error:&error];
                    for(Folder * f in fetched)
                    {
                        f.parentPath = object.fullpath;
                        NSLog(@"%@",f);
                    }
                    [self saveContext];
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        if (handler) {
                            handler(object);
                        }
                    });
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
            
        }];
    }
}

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
    NSManagedObjectContext* context = self.managedObjectContext;
        [[SessionProvider sharedManager] checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline,BOOL isP8){
            if (isP8) {
                if (authorised){
                    NSString * path = folderPath;
                    [context performBlockAndWait:^ {
                        [[ApiP8 filesModule]getFilesForFolder:path withType:type completion:^(NSArray *items){
                        NSArray * filesItems = [self saveItems:items forFolder:folder WithType:type usingContext:context isP8:isP8];
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
                    }];
                }
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
                        
                        [self saveItems:items forFolder:folder WithType:type usingContext:context isP8:isP8];
                        
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
        context = self.managedObjectContext;
    }
    NSMutableArray * existItems = [NSMutableArray new];
    NSString * folderPath = folder ? folder.fullpath : @"";
    if (items.count)
    {
        NSError * error = nil;
        NSMutableArray * existIds = [[NSMutableArray alloc] init];
//                NSMutableArray * existItems = [NSMutableArray new];
        for (NSDictionary * itemRef in items)
        {
            Folder * childFolder = [FEMDeserializer objectFromRepresentation:itemRef mapping: isP8 ? [Folder P8DefaultMapping]:[Folder defaultMapping] context:context];
            [existIds addObject:childFolder.name];
            childFolder.toRemove = [NSNumber numberWithBool:NO];
            childFolder.isP8 = [NSNumber numberWithBool:isP8];
            if (folder)
            {
                childFolder.parentPath = folderPath;
            }
            if ([childFolder.thumb boolValue] && ![childFolder.isFolder boolValue] && ![childFolder.isLink boolValue]) {
                    [existItems addObject:childFolder];
            }
        }
        [self saveContext];
        
        NSFetchRequest * fetchOldAudiosRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchOldAudiosRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        fetchOldAudiosRequest.predicate = [NSPredicate predicateWithFormat:@"NOT name in (%@) AND parentPath = %@ AND type=%@",existIds,folder.fullpath,type];
        NSArray * oldFolders = [self.managedObjectContext executeFetchRequest:fetchOldAudiosRequest error:&error];
        
        for (Folder* fold in oldFolders)
        {
            if (!fold.isDownloaded.boolValue)
            {
                [self deleteOldThumbsAndViews:fold];
                [context deleteObject:[context objectWithID:fold.objectID]];
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
        [self saveContext];
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
                [context deleteObject:[context objectWithID:fold.objectID]];
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
        [self saveContext];

    }
    return existItems;
}

- (void)saveLastUsedFolder:(Folder *)folder{
    NSManagedObjectContext* context = self.managedObjectContext;
//    [context performBlock:^{
        NSError * error = nil;
        NSFetchRequest * fetchLastUsedFolder = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchLastUsedFolder.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        fetchLastUsedFolder.predicate = [NSPredicate predicateWithFormat:@"isFolder = YES AND isLastUsedUploadFolder = YES"];
        NSArray * lastUsedFolders = [context executeFetchRequest:fetchLastUsedFolder error:&error];
        for (Folder *item in lastUsedFolders) {
            item.isLastUsedUploadFolder = [NSNumber numberWithBool:NO];
        }
        
        if (folder){
            folder.isLastUsedUploadFolder = [NSNumber numberWithBool:YES];
        }
        
        if (error)
        {
            NSLog(@"last used path saved with error -> %@",[error userInfo]);
        }
        NSLog(@"last used path saved without error");
        [self saveContext];
//    }];
}

- (Folder *)getLastUsedFolder{
    NSManagedObjectContext* context = self.managedObjectContext;
    NSError * error = nil;
    NSFetchRequest * fetchLastUsedFolder = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
    fetchLastUsedFolder.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    fetchLastUsedFolder.predicate = [NSPredicate predicateWithFormat:@"isFolder = YES AND isLastUsedUploadFolder = YES"];
    NSArray * lastUsedFolders = [context executeFetchRequest:fetchLastUsedFolder error:&error];
    return [lastUsedFolders lastObject];
}

-(Folder *)getFolderWithName:(NSString *)name type:(NSString *)type fullPath:(NSString *)path{
    return [self getObjectWithName:name type:type fullPath:path isFolder:YES];
}


-(Folder *)getObjectWithName:(NSString *)name type:(NSString *)type fullPath:(NSString *)path isFolder:(BOOL) isFolder{
    NSManagedObjectContext* context = self.managedObjectContext;
   __block NSArray * items;
//    [context performBlockAndWait:^{
        NSError * error = nil;
        NSFetchRequest * fetchItem = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchItem.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        fetchItem.predicate = [NSPredicate predicateWithFormat:@"isFolder = %@ AND fullpath = %@ AND name = %@ AND type = %@",[NSNumber numberWithBool:isFolder],path,name,type];
        items = [context executeFetchRequest:fetchItem error:&error];
//    }];
    return [items lastObject];
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

- (void) deleteAllObjects: (NSString *) entityDescription  {
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
    [self saveContext];
    if (error) {
        NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }}];
    
}
@end

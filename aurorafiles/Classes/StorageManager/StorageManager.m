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

- (NSURL *)applicationDocumentsDirectory
{
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.hotger.vMusic" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
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
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
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
                    [context save:nil];
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

- (void)updateFilesWithType:(NSString*)type forFolder:(Folder*)folder withCompletion:(void (^)())handler
{
    NSString * folderPath = folder ? folder.fullpath : @"";
    NSManagedObjectContext* context = self.managedObjectContext;
    
    [context performBlockAndWait:^ {
        [SessionProvider checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline){
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
                    if (items.count)
                    {
                        NSMutableArray * existIds = [[NSMutableArray alloc] init];
                        for (NSDictionary * itemRef in items)
                        {
                            Folder * childFolder = [FEMDeserializer objectFromRepresentation:itemRef mapping:[Folder defaultMapping] context:context];
                            [existIds addObject:childFolder.name];
                            childFolder.toRemove = [NSNumber numberWithBool:NO];
                            if (folder)
                            {
                                childFolder.parentPath = folderPath;
                            }
                        }
                        
                        NSFetchRequest * fetchOldAudiosRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
                        fetchOldAudiosRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
                        fetchOldAudiosRequest.predicate = [NSPredicate predicateWithFormat:@"NOT name in (%@) AND parentPath = %@ AND type=%@",existIds,folder.fullpath,type];
                        NSError * error = nil;
                        NSArray * oldFolders = [self.managedObjectContext executeFetchRequest:fetchOldAudiosRequest error:&error];
                        
                        for (Folder* fold in oldFolders)
                        {
                            if (!fold.isDownloaded.boolValue)
                            {
                                [context deleteObject:[context objectWithID:fold.objectID]];
                            }
                            else
                            {
                                fold.wasDeleted = @YES;
                            }

                        }
                        [context save:&error];
                        if (error)
                        {
                            NSLog(@"%@",[error userInfo]);
                        }
                    }

                    dispatch_async(dispatch_get_main_queue(), ^(){
                        if (handler) {
                            handler();
                        }
                    
                    });
                }];
                
            }
        }];

     }];
}

#pragma mark Fiels Stack

@end

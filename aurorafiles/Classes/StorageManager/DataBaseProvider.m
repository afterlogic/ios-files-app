//
//  DataBaseProvider.m
//  aurorafiles
//
//  Created by Cheshire on 02.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "DataBaseProvider.h"
#import "Folder.h"

@interface DataBaseProvider(){
    
}
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *defaultMOC;
@property (nonatomic, retain) NSOperationQueue *dataBaseOperationsQueue;
@end

@implementation DataBaseProvider

@synthesize defaultMOC = _defaultMOC;
@synthesize operationsMOC = _operationsMOC;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


#pragma mark - initialize
+ (instancetype)sharedProvider{
    static DataBaseProvider *provider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        provider = [[DataBaseProvider alloc]init];
    });
    return provider;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]
         addObserverForName:NSManagedObjectContextDidSaveNotification
         object:nil
         queue:nil
         usingBlock:^(NSNotification* note) {
             NSManagedObjectContext *moc = _defaultMOC;
             if (note && note.object != moc)
//             if (note)
             {
                 [moc performBlock:^(){
                     [moc mergeChangesFromContextDidSaveNotification:note];
                 }];
             }

         }];
        self.dataBaseOperationsQueue = [[NSOperationQueue alloc]init];
        [self.dataBaseOperationsQueue setName:@"com.AuroraFiles.ClearCoreDataOperationsQueue"];
    }
    return self;
}


-(void)setupCoreDataStack{
    _managedObjectModel = [self managedObjectModel];
    _persistentStoreCoordinator = [self persistentStoreCoordinator];
    _defaultMOC = [self defaultMOC];

    
}

#pragma mark - Managed Object Operations

-(void)saveWithBlockUsingTmpContext:(void(^)(NSManagedObjectContext *context))block{
    NSManagedObjectContext *tmpContext = self.operationsMOC;
    [tmpContext performBlock:^{
        if (block){
            block(tmpContext);
        }

        NSError *error = [NSError new];
        if (![tmpContext save:&error])
        {
            //handle error
            DDLogError(@"context saved in childContext- ❌. Error is -> %@",error.localizedDescription);
        }

        [self.defaultMOC performBlock:^{
            NSError *error = [NSError new];
            if ([self.defaultMOC save:&error]) {
                DDLogDebug(@"context saved -> ✅");
            }else{
                DDLogError(@"context saved - ❌. Error is -> %@",error.localizedDescription);
            }
        }];

    }];
}

- (void)saveWithBlock:(void (^)(NSManagedObjectContext *context))block {

//    [self.defaultMOC performBlock:^{
//        if (block) {
//            block(self.defaultMOC);
//        }
//        NSError *error = [NSError new];
//        if ([self.defaultMOC save:&error]) {
//            DDLogDebug(@"context saved -> ✅");
//        }else{
//            DDLogDebug(@"context saved - ❌. Error is -> %@",error.localizedDescription);
//        }
//    }];
    NSBlockOperation *saveOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSManagedObjectContext *tmpContext = self.operationsMOC;
        [tmpContext performBlock:^{
            if (block){
                block(tmpContext);
            }

            NSError *error = [NSError new];
            if (![tmpContext save:&error])
            {
                //handle error
                DDLogError(@"context saved in childContext- ❌. Error is -> %@",error.localizedDescription);
            }else{
                [self.defaultMOC performBlock:^{
                    NSError *error = [NSError new];
                    if ([self.defaultMOC save:&error]) {
                        DDLogDebug(@"context saved -> ✅");
                    }else{
                        DDLogError(@"context saved - ❌. Error is -> %@",error.localizedDescription);
                    }
                }];
            }
        }];
    }];

    [saveOperation setCompletionBlock:^{

    }];

    [self.dataBaseOperationsQueue addOperation:saveOperation];
}

-(void)deleteObject:(NSManagedObject *)object fromContext:(NSManagedObjectContext *)context{
    if ([object isKindOfClass:[NSManagedObject class]]) {
//        if ([context objectWithID:object.objectID]) {
            [context deleteObject:[context objectWithID:object.objectID]];
//        }
    }
    NSError *error = [NSError new];
    
    if ([context save:&error]) {
        DDLogDebug(@"context saved -> ✅");
    }else{
        DDLogError(@"context saved - ❌. Error is -> %@",error.localizedDescription);
    }

}

- (void)saveToPersistentStore {
    NSError *error = [NSError new];
    if ([self.defaultMOC save:&error]) {
        DDLogDebug(@"context saved before App close");
    }else{
        DDLogError(@"context wasn't save. Error is -> %@",error.localizedDescription);
    }
}

- (void)endWork {
    [self saveToPersistentStore];
}

#pragma mark - Properties

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.makopyants.aurorafiles" in the application's documents directory.
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.afterlogic.aurorafiles"];
//    return [[NSFileManager defaultManager] ]
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
        DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
    }

    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)defaultMOC {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_defaultMOC != nil) {
        return _defaultMOC;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }

    _defaultMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_defaultMOC setPersistentStoreCoordinator:coordinator];
    [_defaultMOC setName:@"DefaultMOC"];
    return _defaultMOC;
}

- (NSManagedObjectContext *)operationsMOC {

    NSManagedObjectContext *operationsContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [operationsContext setParentContext:_defaultMOC];
    [operationsContext setName:@"TemporaryMOC"];
    return operationsContext;
}


#pragma mark - Debug
-(void)removeAll{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Folder"];
    [request setIncludesPropertyValues:NO];
    NSError *fetchError = [NSError new];
    NSArray * result = [_defaultMOC executeFetchRequest:request error:&fetchError];
    [self saveWithBlock:^(NSManagedObjectContext *context) {
        for (NSManagedObject *object in result) {
            [_defaultMOC deleteObject:object];
        }
    }];

//    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
//    NSError *deleteError = nil;
//    [_persistentStoreCoordinator executeRequest:delete withContext:_defaultMOC error:&deleteError];
}

@end

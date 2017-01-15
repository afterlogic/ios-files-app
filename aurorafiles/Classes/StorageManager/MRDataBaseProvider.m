//
// Created by Cheshire on 11.01.17.
// Copyright (c) 2017 afterlogic. All rights reserved.
//

#import "MRDataBaseProvider.h"
#import <CoreData/CoreData.h>
#import <MagicalRecord/MagicalRecord.h>

@interface MRDataBaseProvider(){

}
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *defaultMOC;

@end

@implementation MRDataBaseProvider {

}
@synthesize defaultMOC = _defaultMOC;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


#pragma mark - initialize
+ (instancetype)sharedProvider{
    static MRDataBaseProvider *provider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        provider = [[MRDataBaseProvider alloc]init];
    });
    return provider;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
//        [[NSNotificationCenter defaultCenter]
//                addObserverForName:NSManagedObjectContextDidSaveNotification
//                            object:nil
//                             queue:nil
//                        usingBlock:^(NSNotification* note) {
//                            NSManagedObjectContext *moc = self.defaultMOC;
//                            if (note.object != moc)
//                            {
//                                [moc performBlock:^(){
//                                    [moc mergeChangesFromContextDidSaveNotification:note];
//                                }];
//                            }
//
//                        }];
    }
    return self;
}


-(void)setupCoreDataStack{
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:[[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"aurorafiles.sqlite"]];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelDebug];

    _managedObjectModel = [self managedObjectModel];
//    _persistentStoreCoordinator = [self persistentStoreCoordinator];
//    _defaultMOC = [self defaultMOC];


}

#pragma mark - Magical Record

-(void)saveToPersistentStore{
    [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
}

-(void)cleanUP{
    [MagicalRecord cleanUp];
}

-(void)endWork{
    [self saveToPersistentStore];
    [self cleanUP];
}
#pragma mark - Managed Object Operations

-(void)saveWithBlock:(void(^)(NSManagedObjectContext *context))block{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        if (block) {
            block(localContext);
        }
    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
        if (!error && contextDidSave) {
            [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
            NSLog(@"context saved -> %@",contextDidSave ? @"✅" : @"❌");
        }else{
            NSLog(@"context saved - %@. Error is -> %@",contextDidSave ? @"✅" : @"❌" , error);
        }
    }];

//    [_defaultMOC performBlockAndWait:^{
//        if (block) {
//            block(_defaultMOC);
//        }
//    }];
//    NSError *error = [NSError new];
//    if ([_defaultMOC save:&error]) {
//        NSLog(@"context saved -> ✅");
//    }else{
//        NSLog(@"context saved - ❌. Error is -> %@",error.localizedDescription);
//    }

}

-(void)deleteObject:(id)object fromContext:(NSManagedObjectContext *)context{
    if ([object isKindOfClass:[NSManagedObject class]]) {

        [(NSManagedObject *) object MR_deleteEntity];

//        [context deleteObject:(NSManagedObject *)object];
    }
//    NSError *error = [NSError new];
//
//    if ([context save:&error]) {
//        NSLog(@"context saved -> ✅");
//    }else{
//        NSLog(@"context saved - ❌. Error is -> %@",error.localizedDescription);
//    }
}

#pragma mark - Properties


- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.makopyants.aurorafiles" in the application's documents directory.
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.afterlogic.aurorafiles"];
}

- (NSManagedObjectContext *)defaultMOC{
    if (_defaultMOC) {
        return _defaultMOC;
    }
    _defaultMOC = [NSManagedObjectContext MR_defaultContext];

    return _defaultMOC;
}

//- (NSURL *)applicationDocumentsDirectory {
//    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.makopyants.aurorafiles" in the application's documents directory.
//    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.afterlogic.aurorafiles"];
//}
//
- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"aurorafiles" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

//- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
//    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
//    if (_persistentStoreCoordinator != nil) {
//        return _persistentStoreCoordinator;
//    }
//
//    // Create the coordinator and store
//
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"aurorafiles.sqlite"];
//    NSError *error = nil;
//    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:[NSNumber numberWithBool:YES],NSInferMappingModelAutomaticallyOption:[NSNumber numberWithBool:YES]} error:&error]) {
//        // Report any error we got.
//        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
//        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
//        dict[NSUnderlyingErrorKey] = error;
//        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
//        // Replace this with code to handle the error appropriately.
//        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//    }
//
//    return _persistentStoreCoordinator;
//}

//- (NSManagedObjectContext *)defaultMOC {
//    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
//    if (_defaultMOC != nil) {
//        return _defaultMOC;
//    }
//
//    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
//    if (!coordinator) {
//        return nil;
//    }
//    _defaultMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//    [_defaultMOC setPersistentStoreCoordinator:coordinator];
//    return _defaultMOC;
//}


#pragma mark - Debug
-(void)removeAll{

    NSArray *allEntities = _managedObjectModel.entities;
    [allEntities enumerateObjectsUsingBlock:^(NSEntityDescription *entityDescription, NSUInteger idx, BOOL *stop) {
        [NSClassFromString([entityDescription managedObjectClassName]) MR_truncateAll];
    }];
    [self saveToPersistentStore];

//    [_defaultMOC MR_tru]
}




@end
//
//  DataBaseProvider.h
//  aurorafiles
//
//  Created by Cheshire on 02.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "IDataBaseProtocol.h"


@interface DataBaseProvider : NSObject <IDataBaseProtocol>

//@property (nonatomic, readonly, strong) NSManagedObjectContext *defaultMOC;
//@property (nonatomic, readonly, strong) NSManagedObjectContext *operationsMOC;
#pragma mark - Init
+ (instancetype)sharedProvider;


#pragma mark - Core Data
- (void)setupCoreDataStack;
- (void)saveToPersistentStore;
- (void)endWork;

#pragma mark - Managed Object Operations
- (void)saveWithBlock:(void(^)(NSManagedObjectContext *context))block;
- (void)saveWithBlockUsingTmpContext:(void(^)(NSManagedObjectContext *context))block;
- (void)deleteObject:(id)object fromContext:(NSManagedObjectContext *)context;

#pragma mark - Debug
- (void)removeAll;
@end


//
//  IDataBaseProtocol.h
//  aurorafiles
//
//  Created by Cheshire on 02.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol IDataBaseProtocol <NSObject>

@property (nonatomic, readonly, strong) NSManagedObjectContext *defaultMOC;
@property (nonatomic, readonly, strong) NSManagedObjectContext *operationsMOC;

#pragma mark - Init
+ (instancetype)sharedProvider;


#pragma mark - Core Data
-(void)setupCoreDataStack;
-(void)saveToPersistentStore;
-(void)endWork;

#pragma mark - Managed Object Operations

- (void)saveWithBlock:(void (^)(NSManagedObjectContext *context))block;
- (void)saveWithBlock:(void (^)(NSManagedObjectContext *context))block completionBlock:(void(^)()) completionBlock;
- (void)saveWithBlockUsingTmpContext:(void(^)(NSManagedObjectContext *context))block;
- (void)deleteObject:(id)object fromContext:(NSManagedObjectContext *)context;


- (void)removeAll;

@end

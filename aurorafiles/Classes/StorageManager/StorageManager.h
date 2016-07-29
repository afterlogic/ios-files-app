//
//  StorageManager.h
//  aurorafiles
//
//  Created by Michael Akopyants on 15/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Folder.h"

@interface StorageManager : NSObject

+ (instancetype)sharedManager;

@property (readonly, nonatomic, strong) NSManagedObjectContext * managedObjectContext;

- (void)updateFilesWithType:(NSString*)type forFolder:(Folder*)folder withCompletion:(void (^)())handler;
- (void)renameFolder:(Folder*)folder toNewName:(NSString*)newName withCompletion:(void (^)(Folder*))handler;
@end

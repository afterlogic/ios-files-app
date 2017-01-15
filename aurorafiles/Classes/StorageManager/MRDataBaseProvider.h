//
// Created by Cheshire on 11.01.17.
// Copyright (c) 2017 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDataBaseProtocol.h"
#import <CoreData/CoreData.h>

@interface MRDataBaseProvider : NSObject <IDataBaseProtocol>

@property (nonatomic, readonly, strong) NSManagedObjectContext *defaultMOC;
@end
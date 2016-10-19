//
//  files.h
//  aurorafiles
//
//  Created by Cheshire on 19.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuroraModuleProtocol.h"
@interface files : NSObject <AuroraModuleProtocol>
-(NSString *)moduleName;
-(void)getFilesForFolder:(NSString *)folderName withType:(NSString *)type completion:(void (^)(NSDictionary *data, NSString *methodName))handler;
-(void)searchFilesInFolder:(NSString *)folderName withType:(NSString *)type fileName:(NSString *)fileName completion:(void (^)(NSDictionary *data, NSString *methodName))handler;

-(void)getUserFilestorageQoutaWithCompletion:(void(^)(NSString *publicID, NSError *error))handler;
@end

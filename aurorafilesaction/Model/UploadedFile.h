//
//  UploadedFile.h
//  aurorafiles
//
//  Created by Cheshire on 06.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UploadedFile : NSObject

@property (weak, nonatomic) NSString *extension;
@property (weak, nonatomic) NSURL *path;
@property (weak, nonatomic) NSString *type;
@property (weak, nonatomic) NSString *name;
@property (assign, nonatomic) unsigned long long size;
@property (strong, nonatomic) NSURLRequest *request;
@property (weak, nonatomic) NSString *MIMEType;
@property (assign, nonatomic) BOOL savedLocal;

@end

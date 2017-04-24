//
//  UploadedFile.h
//  aurorafiles
//
//  Created by Cheshire on 06.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UploadedFile : NSObject

@property (strong, nonatomic) NSString *extension;
@property (strong, nonatomic) NSURL *path;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *name;
@property (assign, nonatomic) unsigned long long size;
@property (strong, nonatomic) NSURLRequest *request;
@property (strong, nonatomic) NSString *MIMEType;
@property (assign, nonatomic) BOOL savedLocal;
@property (strong, nonatomic) NSURL *webPageLink;

@end

//
//  UploadedFile.m
//  aurorafiles
//
//  Created by Cheshire on 06.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "UploadedFile.h"

@implementation UploadedFile

@synthesize type;
@synthesize path;
@synthesize extension;
@synthesize size;
@synthesize name;


-(void)setRequest:(NSURLRequest *)request{
    _request = request;
}

@end

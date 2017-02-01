//
//  DownloadsTableViewController.h
//  aurorafiles
//
//  Created by Michael Akopyants on 28/06/16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>

static  NSString *loadTypeContainer = @"container";
static  NSString *loadTypeView = @"view";

@interface DownloadsTableViewController : UIViewController
@property (nonatomic, strong) NSString *loadType;

-(void)stopTasks;
@end

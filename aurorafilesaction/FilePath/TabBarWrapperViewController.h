//
//  TabBarWrapperViewController.h
//  aurorafiles
//
//  Created by Cheshire on 28.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Folder.h"
@protocol UploadFolderDelegate
@required
-(void)setCurrentUploadFolder:(NSString *)folderPath root:(NSString *)root;
@end
@interface TabBarWrapperViewController : UIViewController
@property (nonatomic, strong) id <UploadFolderDelegate> delegate;

-(UIBarButtonItem *)getNavRightBar;
-(UIBarButtonItem *)getBackButton;
-(UIBarButtonItem *)getEditButton;

@end

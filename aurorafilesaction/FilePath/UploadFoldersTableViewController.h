//
//  UploadFoldersTableViewController.h
//  aurorafiles
//
//  Created by Cheshire on 28.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Folder.h"

@protocol FolderDelegate
@required
-(void)currentFolder:(Folder *)folder root:(NSString *)root;
@end

@interface UploadFoldersTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIView *activityView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *EditButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) Folder * folder;
@property (nonatomic, assign) BOOL isCorporate;
@property (strong, nonatomic) NSString * type;
@property (nonatomic, strong) id <FolderDelegate> delegate;

- (IBAction)editAction:(id)sender;
- (IBAction)backAction:(id)sender;

@end

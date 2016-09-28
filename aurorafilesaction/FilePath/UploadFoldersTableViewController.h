//
//  UploadFoldersTableViewController.h
//  aurorafiles
//
//  Created by Cheshire on 28.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Folder;

@interface UploadFoldersTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIView *activityView;

@property (strong, nonatomic) Folder * folder;
@property (nonatomic, assign) BOOL isCorporate;

- (IBAction)doneAction:(id)sender;


@end

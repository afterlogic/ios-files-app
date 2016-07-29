//
//  FilesViewController.h
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Folder;
@interface FilesViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *signOutButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;

@property (strong, nonatomic) Folder * folder;
@property (nonatomic, assign) BOOL isCorporate;


- (IBAction)editAction:(id)sender;
- (IBAction)signOut:(id)sender;

@end

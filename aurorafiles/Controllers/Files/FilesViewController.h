//
//  FilesViewController.h
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilesViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *signOutButton;
@property (weak, nonatomic) NSString *folderPath;
@property (weak, nonatomic) NSString *folderName;
@property (nonatomic, assign) BOOL isCorporate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *fileTypeSegmentControl;
- (IBAction)valueChangedSegment:(id)sender;
- (IBAction)signOut:(id)sender;

@end

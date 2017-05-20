//
//  FilesTableViewCell.h
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>
@class Folder;
@protocol FilesTableViewCellDelegate <NSObject>
@required
- (void)tableViewCellDownloadAction:(UITableViewCell*)cell;
- (void)tableViewCellMoreAction:(UITableViewCell*)cell;
@optional
- (void)tableViewCellRemoveAction:(UITableViewCell*)cell;
@end

@interface FilesTableViewCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *downloadActivity;
@property (weak, nonatomic) IBOutlet UIButton *disclosureButton;
@property (weak, nonatomic) IBOutlet UIImageView *fileImageView;
@property (weak, nonatomic) IBOutlet UILabel *titileLabel;

@property BOOL fileDownloaded;

@property (nonatomic, assign) id <FilesTableViewCellDelegate> filesDelegate;

//- (IBAction)downloadAction:(id)sender;
- (IBAction)moreAction:(id)sender;
- (void)setupCellForFile:(Folder *) folder;
+ (CGFloat)cellHeight;
+ (NSString*)cellId;
@end

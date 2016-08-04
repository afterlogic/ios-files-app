//
//  FilesTableViewCell.h
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FilesTableViewCellDelegate <NSObject>
@required
- (void)tableViewCellDownloadAction:(UITableViewCell*)cell;
- (void)tableViewCellMoreAction:(UITableViewCell*)cell;
@optional
- (void)tableViewCellRemoveAction:(UITableViewCell*)cell;
@end

@interface FilesTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *downloadActivity;
@property (weak, nonatomic) IBOutlet UIButton *disclosureButton;
@property (weak, nonatomic) IBOutlet UIImageView *fileImageView;
@property (weak, nonatomic) IBOutlet UILabel *titileLabel;

@property BOOL fileDownloaded;

@property (nonatomic, assign) id <FilesTableViewCellDelegate> delegate;

- (IBAction)downloadAction:(id)sender;
- (IBAction)moreAction:(id)sender;
+ (CGFloat)cellHeight;
+ (NSString*)cellId;
@end

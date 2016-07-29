//
//  FilesTableViewCell.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "FilesTableViewCell.h"
@interface FilesTableViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@end

@implementation FilesTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    self.separatorHeight.constant = 0.5f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.fileImageView.image = nil;
}

- (IBAction)moreAction:(id)sender
{
    [self.delegate tableViewCellMoreAction:self];
}

+ (CGFloat)cellHeight
{
    return 60.0f;
}

- (IBAction)downloadAction:(id)sender
{
    [self.downloadActivity startAnimating];
    [self.delegate tableViewCellDownloadAction:self];
}

+ (NSString*)cellId
{
    return @"FilesTableViewCellId";
}

@end

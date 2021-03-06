//
//  FilesTableViewCell.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "FilesTableViewCell.h"
#import "Folder.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImage+MultiFormat.h>
#import "SDWebImageDownloader.h"
#import "UIImage+Aurora.h"
#import "MBProgressHUD.h"
#import "StorageManager.h"
#import "ApiP8.h"
#import "Settings.h"
@interface FilesTableViewCell (){
    MBProgressHUD *hud;
//    SDWebImageDownloader *p8ImageDownloader;
//    UIActivityIndicatorView *indicator;
//    UIActivityIndicatorView *hudView;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (strong, nonatomic) IBOutlet UIView *disclosureBox;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@end

@implementation FilesTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    [super awakeFromNib];
    self.separatorHeight.constant = 0.5f;
    self.fileImageView.image = nil;
    
    [self.disclosureButton addTarget:self action:@selector(downloadAction) forControlEvents:UIControlEventTouchUpInside];
//    [self.indicator hidesWhenStopped];
    [self.indicator setHidesWhenStopped:YES];
}

-(void)setupCellForFile:(Folder *) folder{

    if (!self.fileImageView.image) {
        [self startHUD];
    }

    if ([[folder isFolder] boolValue])
    {
        
        self.accessoryType = UITableViewCellAccessoryNone;
        self.disclosureButton.alpha = 0.0f;
        self.fileImageView.image = [UIImage imageNamed:@"folder"];
        [self stopHUD];
    }
    else
    {
        
        self.fileImageView.image = nil;

        if (folder.isFolder.boolValue != NO && folder.downloadIdentifier.integerValue != -1)
        {
            [self.downloadActivity startAnimating];
            self.disclosureButton.hidden = YES;
            [self.filesDelegate tableViewCell:self fileReloadAction:folder];
        }
        else
        {
            [self.downloadActivity stopAnimating];
            self.disclosureButton.hidden = NO;
        }
        
        
        [self.disclosureButton setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
        [self.disclosureButton setImage:[UIImage imageNamed:@"onboard"] forState:UIControlStateDisabled];
        self.disclosureButton.enabled = YES;
        [self.disclosureButton setImage: !folder.isDownloaded.boolValue ? [UIImage imageNamed:@"download"] :[UIImage imageNamed:@"onboard"] forState:UIControlStateNormal];
        self.fileDownloaded = folder.isDownloaded.boolValue;
        self.disclosureButton.alpha = 1.0f;
        
        self.accessoryType = UITableViewCellAccessoryNone;
        
        if ([folder.isP8 boolValue]) {
            [[SDWebImageDownloader sharedDownloader] setValue:[NSString stringWithFormat:@"Bearer %@",[Settings authToken]] forHTTPHeaderField:@"Authorization"];
        }else{
            NSString *authHeaderValue = [[SDWebImageDownloader sharedDownloader] valueForHTTPHeaderField:@"Authorization"];
            if (authHeaderValue) {
                [[SDWebImageDownloader sharedDownloader] setValue:nil forHTTPHeaderField:@"Authorization"];
            }
        }
    
        NSString * thumb = [folder embedThumbnailLink];
        UIImage * placeholder = [UIImage assetImageForContentType:[folder validContentType]];
        if (thumb)
        {
            [self.fileImageView sd_setImageWithURL:[NSURL URLWithString:thumb] placeholderImage:placeholder options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                dispatch_async(dispatch_get_main_queue(), ^(){
//                    if(!image){
//                        [self.fileImageView setImage:[UIImage assetImageForContentType:[folder validContentType]]];
//                    }
                    [self stopHUD];
                });
            }];
        }else{
            if (folder.isLink.boolValue && ![folder isImageContentType])
            {
                placeholder = [UIImage imageNamed:@"shotcut"];
            }
            self.fileImageView.image = placeholder;
            [self stopHUD];
        }
    }
    
    self.titileLabel.text = folder.name;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.fileImageView.image = nil;
    [self.fileImageView sd_cancelCurrentImageLoad];
    [[StorageManager sharedManager]stopGettingFileThumb:self.titileLabel.text];
    [self stopHUD];
}

- (IBAction)moreAction:(id)sender
{
    [self.filesDelegate tableViewCellMoreAction:self];
}

+ (CGFloat)cellHeight
{
    return 60.0f;
}

- (void)downloadAction
{
    if (!self.fileDownloaded) {
        [self.downloadActivity startAnimating];
        [self.filesDelegate tableViewCellDownloadAction:self];
    }else{
        [self.filesDelegate tableViewCellRemoveAction:self];
    }
}

-(void)dealloc{
    self.fileImageView.image = nil;
//    self.fileImageView = nil;
    [self.fileImageView sd_cancelCurrentImageLoad];
}

+ (NSString*)cellId
{
    return @"FilesTableViewCellId";
}

-(void)stopHUD{
//    [hudView stopAnimating];
//    if ([MBProgressHUD HUDForView:self.fileImageView]) {
//        [MBProgressHUD hideHUDForView:self.fileImageView animated:YES];
//    }
    [self.indicator stopAnimating];

}

-(void)startHUD{

    [self.indicator startAnimating];
//    if (![MBProgressHUD HUDForView:self.fileImageView]) {
//        [MBProgressHUD showHUDAddedTo:self.fileImageView animated:YES];
//    }

}

@end

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
#import "UIImage+Aurora.h"
#import "MBProgressHUD.h"
#import "StorageManager.h"
#import "ApiP8.h"
@interface FilesTableViewCell (){
       MBProgressHUD *hud;
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
        
        if (folder.downloadIdentifier.integerValue != -1)
        {
            [self.downloadActivity startAnimating];
            self.disclosureButton.hidden = YES;
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
            NSData *data = [NSData dataWithContentsOfFile:[[ApiP8 filesModule]getExistedThumbnailForFile:folder]];
            if(data && data.length!=0){
                UIImage *image = [UIImage imageWithData:data];
                [self.fileImageView setImage:image];
                [self stopHUD];
            }else{
                if ([folder.thumb boolValue] && !folder.isLink.boolValue) {

                }else{
                    UIImage * placeholder = [UIImage assetImageForContentType:[folder validContentType]];
                    if (folder.isLink.boolValue && ![folder isImageContentType])
                    {
                        placeholder = [UIImage imageNamed:@"shotcut"];
                        if (folder.thumbnailLink) {
                            [self.fileImageView sd_setImageWithURL:[NSURL URLWithString:folder.thumbnailLink] placeholderImage:placeholder options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                [self stopHUD];
                            }];
                        }else{
                            self.fileImageView.image =placeholder;
                            [self stopHUD];
                        }
                    }else{
                        self.fileImageView.image =placeholder;
                        [self stopHUD];
                    }
                }
            }
        }else{
            NSString * thumb = [folder embedThumbnailLink];
            UIImage * placeholder = [UIImage assetImageForContentType:[folder validContentType]];
            if (thumb)
            {
                [self.fileImageView sd_setImageWithURL:[NSURL URLWithString:thumb] placeholderImage:nil options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    [self stopHUD];
                }];
            }else{
                if (folder.isLink.boolValue && ![folder isImageContentType])
                {
                    placeholder = [UIImage imageNamed:@"shotcut"];
                }
                self.fileImageView.image =placeholder;
                [self stopHUD];
            }
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
    [self.delegate tableViewCellMoreAction:self];
}

+ (CGFloat)cellHeight
{
    return 60.0f;
}

- (void)downloadAction
{
    if (!self.fileDownloaded) {
        [self.downloadActivity startAnimating];
        [self.delegate tableViewCellDownloadAction:self];
    }else{
        [self.delegate tableViewCellRemoveAction:self];
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

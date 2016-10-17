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
#import "UIImage+Aurora.h"
#import "MBProgressHUD.h"
@interface FilesTableViewCell (){
       MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@end

@implementation FilesTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    [super awakeFromNib];
    self.separatorHeight.constant = 0.5f;
    self.fileImageView.image = nil;
    hud.hidden = YES;
}

-(void)setupCellForFile:(Folder *) folder{
    self.fileImageView.image = nil;
    hud = [MBProgressHUD showHUDAddedTo:self.fileImageView animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud setBackgroundColor:[UIColor clearColor]];
    hud.hidden = NO;
    [hud showAnimated:YES];
    
    if ([[folder isFolder] boolValue])
    {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.disclosureButton.alpha = 0.0f;
        self.fileImageView.image = [UIImage imageNamed:@"folder"];
        [hud hideAnimated:YES];
        hud.hidden = YES;
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
        self.disclosureButton.enabled = !folder.isDownloaded.boolValue;
        
        [self.disclosureButton setImage: !folder.isDownloaded.boolValue ? [UIImage imageNamed:@"download"] :[UIImage imageNamed:@"removeFromDevice"] forState:UIControlStateNormal];
        self.fileDownloaded = folder.isDownloaded.boolValue;
        
        
        self.disclosureButton.alpha = 1.0f;
        
        self.accessoryType = UITableViewCellAccessoryNone;
        
        NSString * thumbnail = [folder embedThumbnailLink];
        UIImage * placeholder = [UIImage assetImageForContentType:[folder validContentType]];
        if (thumbnail)
        {
            [self.fileImageView sd_setImageWithURL:[NSURL URLWithString:thumbnail] placeholderImage:placeholder options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [hud hideAnimated:YES];
                hud.hidden = YES;
            }];
        }else{
            
            if (folder.isLink.boolValue && ![folder isImageContentType])
            {
                placeholder = [UIImage imageNamed:@"shotcut"];
            }
            self.fileImageView.image =placeholder;
            [hud hideAnimated:YES];
            hud.hidden = YES;
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
    [hud hideAnimated:YES];
    hud = nil;
    hud.hidden = YES;
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
    if (!self.fileDownloaded) {
        [self.downloadActivity startAnimating];
        [self.delegate tableViewCellDownloadAction:self];

    }else{
        [self.delegate tableViewCellRemoveAction:self];
    }
}

-(void)dealloc{
    self.fileImageView.image = nil;
    self.fileImageView = nil;
    [self.fileImageView sd_cancelCurrentImageLoad];
}

+ (NSString*)cellId
{
    return @"FilesTableViewCellId";
}

@end

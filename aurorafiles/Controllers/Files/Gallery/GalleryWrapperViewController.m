//
//  GalleryWrapperViewController.m
//  aurorafiles
//
//  Created by Cheshire on 17.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "GalleryWrapperViewController.h"
#import "FileGalleryPageViewController.h"
#import "ImageViewController.h"
#import "GalleryPageDelegate.h"
#import "Folder.h"
#import "StorageManager.h"
#import "Settings.h"
#import "ApiP7.h"
#import "ApiP8.h"

static const int imageNameMinimalLength = 1;

@interface GalleryWrapperViewController () <GalleryPageDelegate, UITextFieldDelegate>{
    UIAlertAction * defaultRenameAction;
}
@property (weak, nonatomic) UIBarButtonItem * moreButton;
@property (weak, nonatomic) UIBarButtonItem * shareButton;
@property (weak, nonatomic) UITextField * folderName;
@property (weak, nonatomic) Folder *currentChoosenItem;
@property (weak, nonatomic) ImageViewController *currentPage;
@property  BOOL isStatusBarHidden;

@end

@implementation GalleryWrapperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    
    UIBarButtonItem * shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareFileAction:)];
    UIBarButtonItem * moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(moreItemAction:)];
    self.moreButton = moreItem;
    self.shareButton = shareItem;
    self.isStatusBarHidden = NO;
    self.navigationItem.rightBarButtonItems = @[self.shareButton, self.moreButton];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(hideNavBar) name:SYPhotoBrowserHideNavbarNotification object:nil];
    // Do any additional setup after loading the view.
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden: NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

-(BOOL)prefersStatusBarHidden{
    return self.isStatusBarHidden;
}


#pragma mark - Actions

-(void)hideNavBar{
    BOOL isHidden = !self.navigationController.navigationBar.isHidden;
    self.isStatusBarHidden = isHidden;
    [UIView animateWithDuration:0.2f animations:^{
        [self.navigationController setNavigationBarHidden: isHidden];
        [self prefersStatusBarHidden];
    }];
}

- (IBAction)moreItemAction:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    
    [alert addAction:[self renameCurrentFileAction]];
    [alert addAction:[self deleteFolderAction]];
    [alert addAction:defaultAction];

    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
        alert.popoverPresentationController.barButtonItem = self.moreButton;
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction*)renameCurrentFileAction
{
    UIAlertAction* renameFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Rename File", @"") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIAlertController * createFolder = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                             [createFolder addTextFieldWithConfigurationHandler:^(UITextField * textField) {
                                                                 Folder * file = self.currentPage.item;
                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 textField.text = [file.name stringByDeletingPathExtension];
                                                                 self.folderName = textField;
                                                                 textField.delegate = self;
                                                             }];
                                                             
                                                             void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
                                                                 Folder * file = self.currentPage.item;
                                                                 [[StorageManager sharedManager] renameOperation:file withNewName:self.folderName.text withCompletion:^(Folder *updatedFile, NSError *error) {
                                                                     if (error) {
                                                                         [[ErrorProvider instance]generatePopWithError:error
                                                                                                            controller:self
                                                                                                    customCancelAction:nil
                                                                                                           retryAction:actionBlock];
                                                                         return;
                                                                     }
                                                                     if (updatedFile) {
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             self.title = updatedFile.name;
                                                                         });
                                                                     }
                                                                 }];
                                                             };
                                                             defaultRenameAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:actionBlock];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                                                                 
                                                             }];
                                                             [createFolder addAction:defaultRenameAction];
                                                             [defaultRenameAction setEnabled:NO];
                                                             [createFolder addAction:cancelAction];
                                                             [self presentViewController:createFolder animated:YES completion:nil];
                                                         }];
    return renameFolder;
    
}

- (UIAlertAction*)deleteFolderAction
{
    UIAlertAction * deleteFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action){
        Folder * object = self.currentPage.item;
        BOOL isCorporate = [object.type isEqualToString:@"corporate"];
        [[StorageManager sharedManager]deleteItem:object controller:self isCorporate:isCorporate completion:^(BOOL succsess, NSError *error) {
            if(error){
                return;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SYPhotoBrowserDeletePageNotification object:nil];
        }];
    }];
    
    return deleteFolder;
}

- (IBAction)shareFileAction:(id)sender
{
    Folder * object = self.currentPage.item;
    if ([[Settings version] isEqualToString:@"P8"]) {
        [[ApiP8 filesModule] getPublicLinkForFileNamed:object.name filePath:object.fullpath type:object.type size:object.size.stringValue isFolder:NO completion:^(NSString *publicLink, NSError *error) {
            DDLogDebug(@"link is -> %@", publicLink);
            NSMutableArray *publicLinkComponents = [publicLink componentsSeparatedByString:@"/"].mutableCopy;
            DDLogDebug(@"link components -> %@",publicLinkComponents);
            [publicLinkComponents replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"%@/?",[Settings domain]]];
            [publicLinkComponents replaceObjectAtIndex:[publicLinkComponents indexOfObject:[publicLinkComponents lastObject]] withObject:@"view"];
            publicLink = [publicLinkComponents componentsJoinedByString:@"/"];
            UIImage * image = self.currentPage.imageView.image;
            NSURL *myWebsite = [NSURL URLWithString:publicLink];
            if (!myWebsite)
            {
                return;
            }
            NSArray *objectsToShare = @[myWebsite];
            if (image)
            {
                objectsToShare = @[myWebsite,image];
            }
            
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
                activityVC.popoverPresentationController.barButtonItem = self.shareButton;
            }
            [self presentViewController:activityVC animated:YES completion:nil];
        }];
    }else{
        [[ApiP7 sharedInstance] getPublicLinkForFileNamed:object.name filePath:object.fullpath type:object.type size:object.size.stringValue isFolder:NO completion:^(NSString *publicLink, NSError *error) {
            DDLogDebug(@"link is -> %@", publicLink);
            NSMutableArray *publicLinkComponents = [publicLink componentsSeparatedByString:@"/"].mutableCopy;
            DDLogDebug(@"link components -> %@",publicLinkComponents);
            [publicLinkComponents replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"%@/share",[Settings domain]]];
            publicLink = [publicLinkComponents componentsJoinedByString:@"/"];
            UIImage * image = self.currentPage.imageView.image;
            NSURL *myWebsite = [NSURL URLWithString:publicLink];
            if (!myWebsite)
            {
                return;
            }
            NSArray *objectsToShare = @[myWebsite];
            if (image)
            {
                objectsToShare = @[myWebsite,image];
            }
            
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
                activityVC.popoverPresentationController.barButtonItem = self.shareButton;
            }
            [self presentViewController:activityVC animated:YES completion:nil];
        }];
    }
}

#pragma mark - TextField Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * currentTextFieldText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL  isActionEnabled =  currentTextFieldText.length>=imageNameMinimalLength ? YES : NO;
    [defaultRenameAction setEnabled:isActionEnabled] ;
    return YES;
}
#pragma mark - Page Delegate

- (void)setCurrentPageController:(ImageViewController *)currentPage{
    if (currentPage) {
        self.currentPage = currentPage;
        self.title = currentPage.item.name;
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"gallery_embed"]) {
        FileGalleryPageViewController *vc = [segue destinationViewController];
        vc.initialPageIndex = self.initialPageIndex;
        vc.itemsList = self.itemsList;
        vc.pageDelegate = self;
    }
}


@end

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

@interface GalleryWrapperViewController () <GalleryPageDelegate>
@property (weak, nonatomic) UIBarButtonItem * moreButton;
@property (weak, nonatomic) UIBarButtonItem * shareButton;
@property (weak, nonatomic) UITextField * folderName;
@property (weak, nonatomic) Folder *currentChoosenItem;
@property (weak, nonatomic) ImageViewController *currentPage;

@end

@implementation GalleryWrapperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    
    UIBarButtonItem * shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareFileAction:)];
    UIBarButtonItem * moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(moreItemAction:)];
    self.moreButton = moreItem;
    self.shareButton = shareItem;
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
    return YES;
}


#pragma mark - Actions

-(void)hideNavBar{
    BOOL isHidden = !self.navigationController.navigationBar.isHidden;
    [UIView animateWithDuration:0.2f animations:^{
        [self.navigationController setNavigationBarHidden: isHidden];
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
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction*)renameCurrentFileAction
{
    UIAlertAction* renameFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Rename File", @"") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIAlertController * createFolder = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                             [createFolder addTextFieldWithConfigurationHandler:^(UITextField * textField) {
                                                                 Folder * file = self.currentPage.item;
//                                                                 [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
                                                                 
                                                                 
                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 textField.text = [file.name stringByDeletingPathExtension];
                                                                 self.folderName = textField;
                                                             }];
                                                             
                                                             UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                 
//                                                                 Folder * file = [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
                                                                 Folder * file = self.currentPage.item;
                                                                 [[StorageManager sharedManager]renameFile:file toNewName:self.folderName.text withCompletion:^(Folder *updatedFile) {
                                                                     if (updatedFile) {
                                                                         self.title = updatedFile.name;
                                                                     }
                                                                 }];
                                                             }];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                                                                 
                                                             }];
                                                             [createFolder addAction:defaultAction];
                                                             [createFolder addAction:cancelAction];
                                                             [self presentViewController:createFolder animated:YES completion:nil];
                                                         }];
    return renameFolder;
    
}

- (UIAlertAction*)deleteFolderAction
{
    UIAlertAction * deleteFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action){
//        Folder * object =  [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
        Folder * object = self.currentPage.item;
        BOOL isCorporate = [object.type isEqualToString:@"corporate"];
        if ([[Settings version] isEqualToString:@"P8"]) {
            [[ApiP8 filesModule]deleteFile:object isCorporate:isCorporate completion:^(BOOL succsess) {
                if (succsess) {
//                    [object.managedObjectContext save:nil];
//                    [self.navigationController popViewControllerAnimated:YES];
                    [[StorageManager sharedManager] deleteItem:object];
                    [[NSNotificationCenter defaultCenter] postNotificationName:SYPhotoBrowserDismissNotification object:nil];
                }
            }];
        }else{
            [[ApiP7 sharedInstance] deleteFile:object isCorporate:isCorporate completion:^(NSDictionary* handler) {
                [[StorageManager sharedManager] deleteItem:object];
//                [self.navigationController popViewControllerAnimated:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:SYPhotoBrowserDismissNotification object:nil];
            }];
        }
    }];
    
    return deleteFolder;
}

- (IBAction)shareFileAction:(id)sender
{
    Folder * object = self.currentPage.item;
//    [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
//    FileGalleryCollectionViewCell * cell = (FileGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:[self.collectionView.indexPathsForVisibleItems firstObject]];
    if ([[Settings version] isEqualToString:@"P8"]) {
        [[ApiP8 filesModule] getPublicLinkForFileNamed:object.name filePath:object.fullpath type:object.type size:object.size.stringValue isFolder:NO completion:^(NSString *publicLink) {
            NSLog(@"link is -> %@", publicLink);
            NSMutableArray *publicLinkComponents = [publicLink componentsSeparatedByString:@"/"].mutableCopy;
            NSLog(@"link components -> %@",publicLinkComponents);
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
            
            [self presentViewController:activityVC animated:YES completion:nil];
        }];
    }else{
        [[ApiP7 sharedInstance] getPublicLinkForFileNamed:object.name filePath:object.fullpath type:object.type size:object.size.stringValue isFolder:NO completion:^(NSString *publicLink) {
            NSLog(@"link is -> %@", publicLink);
            NSMutableArray *publicLinkComponents = [publicLink componentsSeparatedByString:@"/"].mutableCopy;
            NSLog(@"link components -> %@",publicLinkComponents);
            [publicLinkComponents replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"%@/share",[Settings domain]]];
//            [publicLinkComponents replaceObjectAtIndex:[publicLinkComponents indexOfObject:[publicLinkComponents lastObject]] withObject:@"view"];
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
            
            [self presentViewController:activityVC animated:YES completion:nil];
        }];
    }

    

    

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

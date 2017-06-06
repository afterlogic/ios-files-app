
//  FileGalleryCollectionViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 24/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "FileGalleryCollectionViewController.h"
#import "FileGalleryCollectionViewCell.h"
#import "GalleryCollectionFlowLayout.h"
#import "StorageManager.h"
#import "Settings.h"
#import "ApiP8.h"
#import "ApiP7.h"
#import <MagicalRecord/MagicalRecord.h>

@interface FileGalleryCollectionViewController () <UIGestureRecognizerDelegate>
{
    CGPoint _lastTouch;
    UIImageView *snapshotView;
    CGSize cellSize;
    
}
@property (strong, nonatomic) NSArray * items;
@property (strong, nonatomic) StorageManager * manager;
@property (strong, nonatomic) UITapGestureRecognizer * tapGesture;
@property (weak, nonatomic) UIBarButtonItem * moreButton;
@property (weak, nonatomic) UIBarButtonItem * shareButton;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panCollectionGesture;

@property (weak, nonatomic) UITextField * folderName;
@property (weak, nonatomic) UIView * dragView;
@property (weak, nonatomic) Folder *currentViewdItem;
- (IBAction)panCollectionToBack:(id)sender;
@end

@implementation FileGalleryCollectionViewController


- (void)dealloc
{
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView * image = [[UIImageView alloc] init];
    image.frame = self.view.bounds;
    self.backgroundImageView = image;
    self.backgroundImageView.image = self.snapshot;
    self.backgroundImageView.alpha = 0.0f;
    [self.view addSubview:self.backgroundImageView];
    [self.view sendSubviewToBack:self.backgroundImageView];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.manager = [StorageManager sharedManager];
    
    NSFetchRequest * fetchImageFilesItemsRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
    fetchImageFilesItemsRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    fetchImageFilesItemsRequest.predicate = [NSPredicate predicateWithFormat:@"parentPath = %@ AND isFolder == NO AND contentType IN (%@) AND type == %@ AND isP8 = %@",self.folder.fullpath ? self.folder.fullpath : @"",[Folder imageContentTypes],self.currentItem.type, [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
    NSError * error = [NSError new];
    self.items = [[[[StorageManager sharedManager] DBProvider]defaultMOC] executeFetchRequest:fetchImageFilesItemsRequest error:&error];
    
    
    self.panCollectionGesture.delegate = self;
    [self.collectionView addGestureRecognizer:self.panCollectionGesture];
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapsOnImage:)];
    self.tapGesture.delegate = self;
    
    self.collectionView.pagingEnabled = YES;
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    [self.collectionView reloadData];
    
    UIBarButtonItem * shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareFileAction:)];
    UIBarButtonItem * moreItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(moreItemAction:)];
    self.moreButton = moreItem;
    self.shareButton = shareItem;
    [self.collectionView addGestureRecognizer:self.tapGesture];

    self.navigationItem.rightBarButtonItems = @[self.shareButton, self.moreButton];
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:@"FileGalleryCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:[FileGalleryCollectionViewCell cellId]];
    [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:self.panCollectionGesture];
//    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    
    self.navigationController.navigationBar.hidden = NO;
    self.title = self.currentItem.name;
    self.currentViewdItem = self.currentItem;
    
    snapshotView = [UIImageView new];
    [self.view addSubview:snapshotView];
    [snapshotView setFrame:self.collectionView.frame];
    [snapshotView setCenter:self.view.center];
    [snapshotView setContentMode:UIViewContentModeScaleAspectFit];
    snapshotView.alpha = 0.0f;
    
    
    cellSize = self.collectionView.bounds.size;
    // Do any additional setup after loading the view.
    

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    GalleryCollectionFlowLayout * layout = [[GalleryCollectionFlowLayout alloc] init];
//    layout.itemSize = self.view.bounds.size;
    layout.sectionInset = UIEdgeInsetsZero;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [self.collectionView setCollectionViewLayout:layout];
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    [self.view layoutIfNeeded];
    NSInteger row = [self.items indexOfObject:self.currentItem];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    
    [snapshotView setImage:[self getScreenSnapshot]];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillLayoutSubviews{

}


#pragma mark <UIGestureRecognizerDelegate>


-(BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isEqual:self.panCollectionGesture])
    {
        CGPoint translation =[gestureRecognizer translationInView:self.view];
        
        return(translation.x * translation.x < translation.y * translation.y);
    }
    
    return YES;
    
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
                                                                 Folder * file = [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
                                                               

                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 textField.text = [file.name stringByDeletingPathExtension];
                                                                 self.folderName = textField;
                                                             }];
                                                             
                                                             UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                 
                                                                 Folder * file = [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
                                                                 [[StorageManager sharedManager] renameOperation:file withNewName:self.folderName.text withCompletion:^(Folder *updatedFile, NSError *error) {
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
        Folder * object =  [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
        BOOL isCorporate = [object.type isEqualToString:@"corporate"];
        [[StorageManager sharedManager]deleteItem:object controller:self isCorporate:isCorporate completion:^(BOOL succsess, NSError *error) {
            if (succsess) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }];
    
    return deleteFolder;
}

- (IBAction)shareFileAction:(id)sender
{
    Folder * object = [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
    FileGalleryCollectionViewCell * cell = (FileGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:[self.collectionView.indexPathsForVisibleItems firstObject]];
    UIImage * image = cell.imageView.image;
    NSURL *myWebsite = [NSURL URLWithString:[object viewLink]];
    if (!myWebsite)
    {
        return;
    }
    NSArray *objectsToShare = @[myWebsite];
    if (image)
    {
        objectsToShare = @[myWebsite,image];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                                                             applicationActivities:nil];

    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
        activityVC.popoverPresentationController.barButtonItem = self.shareButton;
        activityVC.modalInPopover = YES;
    }

    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)userTapsOnImage:(UITapGestureRecognizer*)recognizer
{
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
    [self.tabBarController.tabBar setHidden:self.navigationController.navigationBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)prefersStatusBarHidden
{
    return self.navigationController.navigationBarHidden;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return cellSize;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation

-(BOOL)shouldAutorotate{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    CGSize collectionViewSize = self.collectionView.bounds.size;
    CGFloat viewWidth = collectionViewSize.width;
    CGFloat viewHeight = collectionViewSize.height;
//
//    [snapshotView setImage:[self getScreenSnapshot]];
//    
//    snapshotView.alpha = 1.0f;
//    self.collectionView.alpha = 0.0f;
//    
    if(viewWidth >= viewHeight){
//        [snapshotView setContentMode:UIViewContentModeScaleAspectFill];
        cellSize = CGSizeMake(viewWidth, viewHeight);
    }else{
//        [snapshotView setContentMode:UIViewContentModeScaleAspectFit];
        cellSize = CGSizeMake(viewWidth, viewHeight);
    }
//
//        [self.collectionView.collectionViewLayout invalidateLayout];
//    [self.collectionView reloadData];
//
    
        CGPoint currentOffset = [self.collectionView contentOffset];
        int currentIndex = currentOffset.x / collectionViewSize.width;
//
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
//        
//        
//     }
//    completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
//        
        CGSize currentSize = size;
        float offset = currentIndex * currentSize.width;
//
        [self.collectionView performBatchUpdates:^{
                [self.collectionView setContentOffset:CGPointMake(offset, 0) animated:NO];
        } completion:nil];
//        self.collectionView.alpha = 1.0f;
//        [UIView animateWithDuration:0.25f animations:^{
//            snapshotView.alpha = 0.0;
//        }];
//
//     }];
//    [self.collectionView performBatchUpdates:nil completion:nil];
//    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FileGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[FileGalleryCollectionViewCell cellId] forIndexPath:indexPath];
    Folder * item = [self.items objectAtIndex:indexPath.row];
    cell.file = item;
    [self.tapGesture requireGestureRecognizerToFail:cell.doubleTap];
    
    return cell;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    FileGalleryCollectionViewCell *sameCell = [self.collectionView.visibleCells lastObject];
    self.title = sameCell.file.name;
    self.currentViewdItem = sameCell.file;
}


- (IBAction)panCollectionToBack:(UIPanGestureRecognizer*)recognizer
{
    CGPoint translation = [recognizer translationInView:self.collectionView];
    CGPoint offset = self.collectionView.center;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
//            self.backgroundImageView.alpha = 1.0f;
            _lastTouch = translation;
            break;
        case UIGestureRecognizerStateChanged:
            offset = CGPointMake(offset.x, offset.y + (translation.y - _lastTouch.y));
            self.collectionView.center = offset;
            _lastTouch = translation;
            break;
        case UIGestureRecognizerStateFailed:
            self.collectionView.alpha = 1.0f;
            self.backgroundImageView.alpha = 0.0f;
            _lastTouch = CGPointZero;
            self.collectionView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            _lastTouch = CGPointZero;
            [self completeHiding];
            break;
        default:
            break;
    }
}

- (void)completeHiding
{
    
    CGFloat mid = CGRectGetMidY([UIScreen mainScreen].bounds);
    BOOL hidingToTop = self.collectionView.center.y < CGRectGetMidY([UIScreen mainScreen].bounds);
    CGPoint center = CGPointMake(self.collectionView.center.x, hidingToTop ? -CGRectGetHeight([UIScreen mainScreen].bounds) : 2*CGRectGetHeight([UIScreen mainScreen].bounds));
    BOOL cancel = NO;
    if (fabs(mid - self.collectionView.center.y) < 100)
    {
        center = CGPointMake(self.collectionView.center.x, mid);
        cancel = YES;
    }
    
    [UIView animateWithDuration:0.2f animations:^(){
        self.collectionView.center = center;
    } completion:^(BOOL finished){
        self.collectionView.alpha = 1.0f;
        self.backgroundImageView.alpha = 0.0f;
        if(!cancel)
        {
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            self.tabBarController.tabBar.hidden = NO;
            [self setNeedsStatusBarAppearanceUpdate];
            [self.navigationController popViewControllerAnimated:NO];
            
        }
    }];

}

- (UIImage *)getScreenSnapshot{
//    // create graphics context with screen size
//    CGRect screenRect = [[UIScreen mainScreen] bounds];
//    UIGraphicsBeginImageContext(screenRect.size);
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    [[UIColor blackColor] set];
//    CGContextFillRect(ctx, screenRect);
//    
//    // grab reference to our window
//    UIWindow *window = [UIApplication sharedApplication].keyWindow;
//    
//    // transfer content into our context
//    [window.layer renderInContext:ctx];
//    UIImage *screengrab = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screengrab = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    
    return screengrab;
}
@end

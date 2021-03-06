//
//  FileGalleryCollectionViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 24/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "EXFileGalleryCollectionViewController.h"
#import "EXFileGalleryCollectionViewCell.h"
#import <MobileCoreServices/MobileCoreServices.h>

//#import "StorageManager.h"
//#import "API.h"

@interface EXFileGalleryCollectionViewController () <UIGestureRecognizerDelegate>
{
    CGPoint _lastTouch;
    NSUInteger itemsCount;
}

//@property (strong, nonatomic) StorageManager * manager;
@property (strong, nonatomic) UITapGestureRecognizer * tapGesture;
@property (weak, nonatomic) UIBarButtonItem * shareButton;
//@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panCollectionGesture;
@property (weak, nonatomic) UIBarButtonItem * moreButton;
@property (weak, nonatomic) UITextField * folderName;
@property (weak, nonatomic) UIView * dragView;
//- (IBAction)panCollectionToBack:(id)sender;
@end

@implementation EXFileGalleryCollectionViewController


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
    itemsCount = 0;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapsOnImage:)];
    self.tapGesture.delegate = self;
    
    
    
    //self.items = [self.manager.managedObjectContext executeFetchRequest:fetchImageFilesItemsRequest error:&error];
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
    [self.collectionView registerNib:[UINib nibWithNibName:@"EXFileGalleryCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:[EXFileGalleryCollectionViewCell cellId]];
    //[self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:self.panCollectionGesture];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
    layout.sectionInset = UIEdgeInsetsZero;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    [self.collectionView setCollectionViewLayout:layout];
    if (itemsCount > 0) {
        if (self.currentItem) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self.items indexOfObject:self.currentItem] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically|UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
    }
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    itemsCount = self.items.count;
    [self.collectionView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size
          withTransitionCoordinator:coordinator];
    self.collectionView.alpha = 0.0f;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self.collectionView.collectionViewLayout invalidateLayout];
         
     }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         if(self.currentItem){
             [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self.items indexOfObject:self.currentItem] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically|UICollectionViewScrollPositionCenteredHorizontally animated:NO];
         }
         self.collectionView.alpha = 1.0f;
     }];
}

- (void)setDelegate:(id<GalleryDelegate>)delegate{
    if (delegate) {
        _delegate = delegate;
    }
}

#pragma mark <UICollectionViewLayoutDelegate>

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}


#pragma mark <UIGestureRecognizerDelegate>


-(BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
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
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction*)renameCurrentFileAction
{
    UIAlertAction* renameFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Rename File", @"") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIAlertController * createFolder = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                             [createFolder addTextFieldWithConfigurationHandler:^(UITextField * textField) {
                                                                 UploadedFile * file = [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
                                                               

                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 textField.text = [file.name stringByDeletingPathExtension];
                                                                 self.folderName = textField;
                                                             }];
                                                             
                                                             UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                 UploadedFile * file = [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
                                                                 if (!file)
                                                                 {
                                                                     return ;
                                                                 }
                                                                 NSString * oldName = file.name;
                                                                 
                                                                 file.name = [self.folderName.text stringByAppendingPathExtension:[oldName pathExtension]];
                                                                 self.title = file.name;
                                                                 
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
        UploadedFile * object =  [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
        //BOOL isCorporate = [object.type isEqualToString:@"corporate"];
        
        //[[API sharedInstance] deleteFile:object isCorporate:isCorporate completion:^(NSDictionary* handler) {
          //  object.wasDeleted = @YES;
            //[object.managedObjectContext save:nil];
            //[self.navigationController popViewControllerAnimated:YES];
       // }];
    }];
    
    return deleteFolder;
}

- (IBAction)shareFileAction:(id)sender
{
    UploadedFile * object = [self.items objectAtIndex:[[self.collectionView.indexPathsForVisibleItems firstObject] row]];
    EXFileGalleryCollectionViewCell * cell = (EXFileGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:[self.collectionView.indexPathsForVisibleItems firstObject]];
    UIImage * image = cell.imageView.image;
    NSURL *myWebsite = object.path;
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
    CGSize collectionViewSize = collectionView.bounds.size;
    return collectionViewSize;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    int currentPage = self.collectionView.contentOffset.x / self.collectionView.bounds.size.width;
    float width = self.collectionView.bounds.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        [self.self.collectionView setContentOffset:CGPointMake(width * currentPage, 0.0) animated:NO];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return itemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EXFileGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[EXFileGalleryCollectionViewCell cellId] forIndexPath:indexPath];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    UploadedFile * item = [self.items objectAtIndex:indexPath.row];
    EXFileGalleryCollectionViewCell *currentCell = (EXFileGalleryCollectionViewCell *)cell;
    self.title = item.name;
    // Configure the cell
    currentCell.file = item;
    if (![item.type isEqualToString:(NSString *)kUTTypeURL]) {
        [self.tapGesture requireGestureRecognizerToFail:currentCell.doubleTap];
    }

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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    if (self.items.count > 1) {
        CGFloat pageWidth = self.collectionView.frame.size.width;
        int pageNum = self.collectionView.contentOffset.x/ pageWidth;
        [self.delegate selectGalleryItem:[_items objectAtIndex:pageNum]];
    }
    
}

#pragma mark - Setters
-(void)setItems:(NSArray *)items{
    _items = items;
    if (_items.count > 0) {
        self.currentItem = [_items objectAtIndex:0];
    }
    [self.collectionView reloadData];
}
@end

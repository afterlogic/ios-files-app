//
//  EXPreviewFileGalleryCollectionViewController.m
//  aurorafiles
//
//  Created by Cheshire on 27.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "EXPreviewFileGalleryCollectionViewController.h"
#import "EXPreviewFileGalleryCollectionViewCell.h"
#import "EXConstants.h"



@interface EXPreviewFileGalleryCollectionViewController (){
    NSInteger currentInterfaceOrientation;
    NSIndexPath * lastSelectedItem;
}

@end

@implementation EXPreviewFileGalleryCollectionViewController

- (void)dealloc
{
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:@"EXPreviewFileGalleryCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:[EXPreviewFileGalleryCollectionViewCell cellId]];
    self.collectionView.userInteractionEnabled = NO;
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 3;
    layout.minimumInteritemSpacing = 5;
    [self setLayout:layout ItemsSizeForDevider:scaleFactor1Devider];
    
    layout.sectionInset = UIEdgeInsetsMake(5, 13, 5, 13);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;

    [self.collectionView setCollectionViewLayout:layout];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self.items indexOfObject:self.currentItem] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically|UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewWillLayoutSubviews{
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    if([NSObject orientation] == InterfaceOrientationTypePortrait){
       [self setLayout:layout ItemsSizeForDevider:scaleFactor1Devider];
    }else{
       [self setLayout:layout ItemsSizeForDevider:landscapeScaleFactor1Devider];
    }
}

-(void)setLayout:(UICollectionViewFlowLayout *) layout ItemsSizeForDevider:(CGFloat)devider{
    CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat height = 0;
    if([NSObject orientation] == InterfaceOrientationTypePortrait){
        height = iOSDeviceScreenSize.height;
    }else{
        height = iOSDeviceScreenSize.width;
    }
    if(height > 568){
        if([NSObject orientation] == InterfaceOrientationTypePortrait){
            layout.itemSize = CGSizeMake(65, 65);
            layout.minimumInteritemSpacing = 5;
        }else{
            layout.itemSize = CGSizeMake(65 * landscapeScaleFactor2Devider, 65 * landscapeScaleFactor2Devider);
            layout.minimumInteritemSpacing = 4;
        }
    }
    
    if (height <= 568){
        layout.itemSize = CGSizeMake(65 * devider, 65 * devider);
    }
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
         [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self.items indexOfObject:self.currentItem] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically|UICollectionViewScrollPositionCenteredHorizontally animated:NO];
         self.collectionView.alpha = 1.0f;
     }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)setItems:(NSArray *)items{
    _items = items;
    NSLog(@"preview items is -> %@", _items);
    self.currentItem = [_items objectAtIndex:0];
    [self.collectionView reloadData];
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
    EXPreviewFileGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[EXPreviewFileGalleryCollectionViewCell cellId] forIndexPath:indexPath];
    UploadedFile * item = [self.items objectAtIndex:indexPath.row];
    
    self.title = item.name;
    // Configure the cell
    
    cell.file = item;
    
    cell.layer.masksToBounds = YES;
    cell.layer.cornerRadius = 6;
    
    if ([self.items indexOfObject:item] == 0) {
        lastSelectedItem = indexPath;
        cell.selectedView.hidden = NO;
        [self highlightItem:item];
    }else{
        cell.selectedView.hidden = YES;
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    //NSLog(@"did select item at index -> %li",(long)indexPath.row);
    //EXPreviewFileGalleryCollectionViewCell *cell = (EXPreviewFileGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    //cell.selectedView.hidden = YES;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //NSLog(@"did select item at index -> %li",(long)indexPath.row);
    //[self collectionView:collectionView didSelectItemAtIndexPath:lastSelectedItem];
    //EXPreviewFileGalleryCollectionViewCell *cell = (EXPreviewFileGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    //cell.selectedView.hidden = NO;
    //lastSelectedItem = indexPath;
}

- (void)highlightItem:(UploadedFile *)item{
    for (EXPreviewFileGalleryCollectionViewCell *cell in self.collectionView.visibleCells){
        cell.selectedView.hidden = YES;
        if ([cell.file isEqual:item]) {
            [self.collectionView selectItemAtIndexPath:[self.collectionView indexPathForCell:cell] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
}



#pragma mark <UICollectionViewLayoutDelegate>

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}



/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/



@end

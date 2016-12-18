//
//  FileGalleryPageViewController.m
//  aurorafiles
//
//  Created by Cheshire on 16.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "FileGalleryPageViewController.h"
#import "ImageViewController.h"


static const CGFloat SYPhotoBrowserPageControlHeight = 40.0;
//static const CGFloat SYPhotoBrowserCaptionLabelPadding = 20.0;

@interface FileGalleryPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>


// UI Property
@property (nonatomic, strong) UIPageControl *systemPageControl;
@property (nonatomic, strong) UILabel *labelPageControl;

// Data Property
@property (nonatomic, strong) NSMutableArray *photoViewControllerArray;
@property (nonatomic, copy) NSArray *imageSourceArray;
@property (nonatomic, copy) NSString *caption;



@property (weak, nonatomic) ImageViewController * currentImageVc;

@end

@implementation FileGalleryPageViewController

//- (instancetype)init {
//    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
//                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
//                                  options:@{UIPageViewControllerOptionInterPageSpacingKey: @(10)}];
//    if (self) {
//        self.dataSource = self;
//        self.delegate = self;
//        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
//        self.enableStatusBarHidden = NO;
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDissmissNotification:) name:SYPhotoBrowserDismissNotification object:nil];
////        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLongPressNotification:) name:SYPhotoBrowserLongPressNotification object:nil];
//    }
//    return self;
//}

-(void)setItemsList:(NSArray<Folder *> *)itemsList{
    self.imageSourceArray = itemsList;
}

-(void)setPageDelegate:(id<GalleryPageDelegate>)pageDelegate{
    _pageDelegate = pageDelegate;
}

- (instancetype)initWithImageSourceArray:(NSArray<Folder *>*)imageSourceArray {
    self = [self init];
    if (self) {
        self.imageSourceArray = imageSourceArray;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.dataSource = self;
    self.delegate = self;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.enableStatusBarHidden = NO;
//    self.navigationController.navigationBarHidden = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDissmissNotification:) name:SYPhotoBrowserDismissNotification object:nil];
    

    
    [self loadPhotoViewControllers];
    [self updatePageControlWithPageIndex:self.initialPageIndex];
    [self updateCationLabelWithCaption:self.caption];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

}



- (void)dealloc {
    self.dataSource = nil;
    self.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark - PageView DataSouce

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = ((ImageViewController *)viewController).pageIndex;
    if (index == 0) {
        return nil;
    } else {
        index--;
        ImageViewController *photoViewController = self.photoViewControllerArray[index];
        return photoViewController;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = ((ImageViewController *)viewController).pageIndex;
    if (index == self.photoViewControllerArray.count - 1) {
        return nil;
    } else {
        index++;
        ImageViewController *photoViewController = self.photoViewControllerArray[index];
        return photoViewController;
    }
}

#pragma mark - PageView Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    if (self.pageDelegate){
        [self.pageDelegate setCurrentPageController:((ImageViewController *)pendingViewControllers.lastObject)];
    }
    [self updatePageControlWithPageIndex:((ImageViewController *)pendingViewControllers.lastObject).pageIndex];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        [((ImageViewController *)previousViewControllers.lastObject) resetImageSize];
    } else {
        [self updatePageControlWithPageIndex:((ImageViewController *)previousViewControllers.lastObject).pageIndex];
    }
}

#pragma mark - Notification Handler

- (void)handleDissmissNotification:(NSNotification *)notification {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

//- (void)handleLongPressNotification:(NSNotification *)notification {
//    if ([self.photoBrowserDelegate respondsToSelector:@selector(photoBrowser:didLongPressImage:)]) {
//        [self.photoBrowserDelegate photoBrowser:self didLongPressImage:notification.object];
//    }
//}

#pragma mark - Private method

- (void)loadPhotoViewControllers {
    for (NSUInteger index = 0; index < self.imageSourceArray.count; index++) {
        id imageSource = self.imageSourceArray[index];
        ImageViewController *photoViewController = [[ImageViewController alloc]initWithNibName:@"ImageViewController" bundle:[NSBundle mainBundle]];
        photoViewController.item = imageSource;
        photoViewController.pageIndex = index;
//        photoViewController setnavi
//        ImageViewController *photoViewController = [[SYPhotoViewController alloc] initWithImageSouce:imageSource pageIndex:index];
        [self.photoViewControllerArray addObject:photoViewController];
    }

    __block FileGalleryPageViewController *weakSelf = self;
    [self setViewControllers:@[self.photoViewControllerArray[self.initialPageIndex]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        if (finished) {
            [weakSelf.pageDelegate setCurrentPageController:[weakSelf.photoViewControllerArray objectAtIndex:[weakSelf initialPageIndex]]];
        }
    }];
}

- (void)updateCationLabelWithCaption:(NSString *)caption {
//    if (caption.length) {
//        self.captionLabel.text = caption;
//        CGRect captionLabelFrame = self.captionLabel.frame;
//        CGSize captionLabelSize = [self.captionLabel sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.bounds) - SYPhotoBrowserCaptionLabelPadding*2, CGFLOAT_MAX)];
//        captionLabelFrame.size.height = captionLabelSize.height;
//        captionLabelFrame.origin.y -= CGRectGetHeight(captionLabelFrame);
//        self.captionLabel.frame = captionLabelFrame;
//        if (self.pageControlStyle == SYPhotoBrowserPageControlStyleSystem) {
//            CGRect pageControlFrame = self.systemPageControl.frame;
//            pageControlFrame.origin.y -= CGRectGetHeight(captionLabelFrame);
//            self.systemPageControl.frame = pageControlFrame;
//        } else {
//            CGRect pageControlFrame = self.labelPageControl.frame;
//            pageControlFrame.origin.y -= CGRectGetHeight(captionLabelFrame);
//            self.labelPageControl.frame = pageControlFrame;
//        }
//    }
}

- (void)updatePageControlWithPageIndex:(NSUInteger)pageIndex {
//    if (self.pageControlStyle == SYPhotoBrowserPageControlStyleSystem) {
//        self.systemPageControl.numberOfPages = self.imageSourceArray.count;
//        self.systemPageControl.currentPage = pageIndex;
//    } else {
//        self.labelPageControl.text = [NSString stringWithFormat:@"%@/%@", @(pageIndex+1), @(self.imageSourceArray.count)];
//    }
}

#pragma mark - Property method

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (NSMutableArray *)photoViewControllerArray {
    if (_photoViewControllerArray == nil) {
        _photoViewControllerArray = [NSMutableArray array];
    }
    return _photoViewControllerArray;
}

- (UIPageControl *)systemPageControl {
    if (_systemPageControl == nil) {
        _systemPageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-SYPhotoBrowserPageControlHeight, CGRectGetWidth(self.view.bounds), SYPhotoBrowserPageControlHeight)];
        _systemPageControl.userInteractionEnabled = NO;
        _systemPageControl.hidesForSinglePage = YES;
        [self.view addSubview:_systemPageControl];
    }
    return _systemPageControl;
}

- (UILabel *)labelPageControl {
    if (_labelPageControl == nil) {
        _labelPageControl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-SYPhotoBrowserPageControlHeight, CGRectGetWidth(self.view.bounds), SYPhotoBrowserPageControlHeight)];
        _labelPageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        _labelPageControl.textAlignment = NSTextAlignmentCenter;
        _labelPageControl.textColor = [UIColor whiteColor];
        _labelPageControl.font = [UIFont systemFontOfSize:14.0];
        [self.view addSubview:_labelPageControl];
    }
    return _labelPageControl;
}

//- (SYPhotoBrowserCaptionLabel *)captionLabel {
//    if (_captionLabel == nil) {
//        CGRect frame = CGRectMake(0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), 0.0);
//        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(SYPhotoBrowserCaptionLabelPadding, SYPhotoBrowserCaptionLabelPadding, SYPhotoBrowserCaptionLabelPadding, SYPhotoBrowserCaptionLabelPadding);
//        _captionLabel = [[SYPhotoBrowserCaptionLabel alloc] initWithFrame:frame edgeInsets:edgeInsets];
//        _captionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
//        _captionLabel.numberOfLines = 0;
//        _captionLabel.textColor = [UIColor whiteColor];
//        _captionLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
//        _captionLabel.font = [UIFont systemFontOfSize:18.0];
//        [self.view addSubview:_captionLabel];
//    }
//    return _captionLabel;
//}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

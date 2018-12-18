//
//  TabBarWrapperViewController.m
//  aurorafiles
//
//  Created by Cheshire on 28.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "TabBarWrapperViewController.h"
#import "UploadFoldersTableViewController.h"
#import <BugfenderSDK/BugfenderSDK.h>
#import "StorageManager.h"
#import "WormholeProvider.h"
#import "ApiP7.h"
#import "ApiP8.h"
#import "UserLoggedOutViewController.h"

@interface TabBarWrapperViewController ()<UITabBarControllerDelegate, FolderDelegate>{
    NSMutableArray *folders;
}

@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, weak) UploadFoldersTableViewController *currentFolderController;
@property (nonatomic, strong) UIBarButtonItem *navRightButton;
@property (nonatomic, strong) UIBarButtonItem *editRightButton;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) NSString *selectedFolderPath;
@property (nonatomic, strong) NSString *selectedRootPath;
@property (nonatomic, strong) Folder *savedFolder;
@property (nonatomic, strong) NSMutableArray *views;
@end

@implementation TabBarWrapperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareController];
}

- (void)prepareController{
    self.tabBarController.delegate = self;
    self.views = [NSMutableArray new];
    folders = [NSMutableArray new];
    [[ApiP7 sharedInstance]cancelAllOperations];
    [ApiP8 cancelAllOperations];
    [self.tabBarController.viewControllers makeObjectsPerformSelector:@selector(view)];
    
    self.currentFolderController = (UploadFoldersTableViewController *)self.tabBarController.viewControllers.firstObject;
    self.currentFolderController.delegate = self;
    self.selectedFolderPath = @"";
    self.selectedRootPath = self.currentFolderController.type;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navRightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(donePressed)];
    self.editRightButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit"] style:UIBarButtonItemStylePlain target:self.currentFolderController action:@selector(editAction:)];
    self.backButton = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self.currentFolderController action:@selector(backAction:)];
    
    self.navigationItem.rightBarButtonItems = @[self.navRightButton,self.editRightButton];
    
    [self.navigationItem.backBarButtonItem setTarget:self.currentFolderController];
    [self.navigationItem.backBarButtonItem setAction:@selector(backAction:)];
    [self.navigationController.navigationController setTitle:self.selectedRootPath];

    self.currentFolderController.doneButton = self.navRightButton;
    self.currentFolderController.editButton = self.editRightButton;
    
    [self currentFolder:self.currentFolderController.folder root:self.currentFolderController.type];
    [self setupObservers];
}

-(void)viewWillDisappear:(BOOL)animated{
    DDLogDebug(@"%s will disappear",__PRETTY_FUNCTION__);
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setDelegate:(id<UploadFolderDelegate>)delegate{
    if (delegate) {
        _delegate = delegate;
    }
}

-(void)donePressed{
    NSString *folderPath = @"";
    if (self.selectedFolderPath) {
        folderPath = self.selectedFolderPath;
    }
    [self.delegate setCurrentUploadFolder:folderPath root:self.selectedRootPath];
    NSString *name = [[folderPath componentsSeparatedByString:@"/"]lastObject];
    NSMutableArray *pathParts = [folderPath componentsSeparatedByString:@"/"].mutableCopy;
    [pathParts removeLastObject];
    NSString *parrentPath = [pathParts componentsJoinedByString:@"/"];
    DDLogDebug(@"current folder parrent path -> %@",parrentPath);
    NSDictionary *lastSavedPath = @{@"Type":self.selectedRootPath,
                                    @"Name":name,
                                    @"ParrentPath":parrentPath,
                                    @"FullPath":folderPath};
    [[StorageManager sharedManager]saveLastUsedFolder:lastSavedPath];
}

#pragma mark - TabBar Delegates
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    if ([viewController isKindOfClass:[UploadFoldersTableViewController class]]) {
        self.currentFolderController = (UploadFoldersTableViewController *)viewController;
        self.currentFolderController.delegate = self;
        self.currentFolderController.doneButton = self.navRightButton;
        self.currentFolderController.backButton = self.backButton;
        
        self.editRightButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit"] style:UIBarButtonItemStylePlain target:self.currentFolderController action:@selector(editAction:)];
        self.navigationItem.rightBarButtonItems = @[self.navRightButton,self.editRightButton];
        self.currentFolderController.editButton = self.editRightButton;
        
        self.selectedRootPath = self.currentFolderController.type;
        self.selectedFolderPath = @"";
        
//        [self.navigationController setTitle:self.selectedRootPath];
    }
}

#pragma mark - Public Methods

-(UIBarButtonItem *)getNavRightBar{
    return self.navRightButton;
}

-(UIBarButtonItem *)getBackButton{
    return self.backButton;
}

-(UIBarButtonItem *)getEditButton{
    return self.editRightButton;
}

#pragma mark - Folder

-(void)currentFolder:(Folder *)folder root:(NSString *)root{
    BFLog(@"current root -> %@ | folder -> %@",root, folder.fullpath);
    self.selectedFolderPath = folder.fullpath;
    self.selectedRootPath = root;
    self.savedFolder = folder;
}

#pragma mark - Helpers
- (void)generateViewForFolder:(Folder *)item{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainInterface" bundle: nil];
        NSString *stId = [item.type isEqualToString:@"corporate"] ? @"corporateFiles" : @"personalFiles";
        UploadFoldersTableViewController *vc = [storyboard instantiateViewControllerWithIdentifier:stId];;
        vc.folder = item;
        vc.delegate = self;
        vc.isCorporate = [item.type isEqual:@"corporate"] ? YES : NO;
        vc.doneButton = self.navRightButton;
        [self.views addObject:vc];
}

-(void)setupObservers{
    [[WormholeProvider instance]catchNotification:AUWormholeNotificationUserSignOut handler:^(id  _Nullable messageObject) {
        [self showLoggedOutModelView];
    }];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(voidFunc) name:@"dismissModalView" object:nil];
}

- (void)showLoggedOutModelView{
//    UIStoryboard *board = [UIStoryboard storyboardWithName:@"MainInterface" bundle:nil];
//    UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"UserLoggedOutViewController"];
//    vc.view.hidden = NO;
//    
//    if (![NSStringFromClass([self.presentedViewController class]) isEqualToString:NSStringFromClass([UserLoggedOutViewController class])]){
//        [self presentViewController:vc animated:nil completion:nil];
//    }
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

-(void)voidFunc{
    DDLogDebug(@"void func from TabBarWrapperViewController");
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"tabbar_embed"]) {
        self.tabBarController = (UITabBarController *)[segue destinationViewController];
    }
}


@end

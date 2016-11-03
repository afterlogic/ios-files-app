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
#import "Folder.h"
#import "API.h"
#import "ApiP8.h"

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
    self.tabBarController.delegate = self;
    self.views = [NSMutableArray new];
    folders = [NSMutableArray new];
    [[API sharedInstance]cancelAllOperations];
    [ApiP8 cancelAllOperations];
    self.savedFolder = [[StorageManager sharedManager]getLastUsedFolder];
    if (self.savedFolder) {
        [self generateViewForFolder:self.savedFolder];
    }
    [self.tabBarController.viewControllers makeObjectsPerformSelector:@selector(view)];
    if (self.savedFolder) {
        self.currentFolderController = (UploadFoldersTableViewController *)[self.tabBarController.viewControllers objectAtIndex:[self.savedFolder.type isEqual:@"personal"] ? 0 :1];
        self.selectedFolderPath = self.savedFolder.fullpath;
        self.currentFolderController.isCorporate = [self.savedFolder.type isEqual:@"corporate"];
        self.currentFolderController.controllersStack = self.views;
        if (self.savedFolder) {
            [self.tabBarController setSelectedIndex:[self.savedFolder.type isEqual:@"personal"] ? 0 :1];
        }
    }else{
        self.currentFolderController = (UploadFoldersTableViewController *)self.tabBarController.viewControllers.firstObject;
        self.currentFolderController.delegate = self;
        self.selectedFolderPath = @"";
        self.selectedRootPath = self.currentFolderController.type;
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navRightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(donePressed)];
    self.editRightButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit"] style:UIBarButtonItemStylePlain target:self.currentFolderController action:@selector(editAction:)];
    self.backButton = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self.currentFolderController action:@selector(backAction:)];
    self.navigationItem.rightBarButtonItems = @[self.navRightButton,self.editRightButton];
    
    [self.navigationItem.backBarButtonItem setTarget:self.currentFolderController];
    [self.navigationItem.backBarButtonItem setAction:@selector(backAction:)];
    
    self.currentFolderController.doneButton = self.navRightButton;
    
    [self currentFolder:self.currentFolderController.folder root:self.currentFolderController.type];
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
    [[StorageManager sharedManager]saveLastUsedFolder:self.savedFolder];
}

#pragma mark - TabBar Delegates
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    if ([viewController isKindOfClass:[UploadFoldersTableViewController class]]) {
        self.currentFolderController = (UploadFoldersTableViewController *)viewController;
        self.currentFolderController.delegate = self;
        self.currentFolderController.doneButton = self.navRightButton;
        self.currentFolderController.backButton = self.backButton;
        self.selectedRootPath = self.currentFolderController.type;
        self.selectedFolderPath = @"";
    }
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
//    for (Folder *item in folds) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainInterface" bundle: nil];
        NSString *stId = [item.type isEqualToString:@"corporate"] ? @"corporateFiles" : @"personalFiles";
        UploadFoldersTableViewController *vc = [storyboard instantiateViewControllerWithIdentifier:stId];;
        vc.folder = item;
        vc.delegate = self;
        vc.isCorporate = [item.type isEqual:@"corporate"] ? YES : NO;
        vc.doneButton = self.navRightButton;
        [self.views addObject:vc];
//    }
}

//-(void)generatePathsFromEndPointFoldertoRoot:(Folder *)endpointFolder {
//    if (endpointFolder) {
//        if (![folders containsObject:endpointFolder] ) {
//            [folders insertObject:endpointFolder atIndex:0];
//        }
//        NSArray *parts = [endpointFolder.parentPath componentsSeparatedByString:@"/"];
//        if (endpointFolder.parentPath) {
//            NSString *name =  [parts lastObject];
//            NSString *fullPath = endpointFolder.parentPath;
//            NSString *type = endpointFolder.type;
//            if (name.length) {
//                [self getFolderWithName:name fullPath:fullPath type:type];
//            }
//        }else{
//            NSLog(@"same log %@",folders);
//            [self generateViewsStack:folders];
//        }
//    }
//}

//-(void)getFolderWithName:(NSString *)name fullPath:(NSString *)path type:(NSString *)type{
//    Folder *endpointFolder = [[StorageManager sharedManager]getFolderWithName:name type:type fullPath:path];
//    [self generateViewsStack:@[endpointFolder]];
//}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"tabbar_embed"]) {
        self.tabBarController = (UITabBarController *)[segue destinationViewController];
    }
}


@end

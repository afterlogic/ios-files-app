//
//  TabBarWrapperViewController.m
//  aurorafiles
//
//  Created by Cheshire on 28.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "TabBarWrapperViewController.h"
#import "UploadFoldersTableViewController.h"

@interface TabBarWrapperViewController ()<UITabBarControllerDelegate, FolderDelegate>{
    
}

@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, weak) UploadFoldersTableViewController *currentFolderController;
@property (nonatomic, strong) UIBarButtonItem *navRightButton;
@property (nonatomic, strong) UIBarButtonItem *editRightButton;
@property (nonatomic, strong) NSString *selectedFolderPath;
@property (nonatomic, strong) NSString *selectedRootPath;
@end

@implementation TabBarWrapperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.delegate = self;
    [self.tabBarController.viewControllers makeObjectsPerformSelector:@selector(view)];
    self.currentFolderController = (UploadFoldersTableViewController *)self.tabBarController.viewControllers.firstObject;
    self.currentFolderController.delegate = self;
    self.selectedFolderPath = @"";
    self.selectedRootPath = self.currentFolderController.type;
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navRightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(donePressed)];
    self.editRightButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit"] style:UIBarButtonItemStylePlain target:self.currentFolderController action:@selector(editAction:)];
    self.navigationItem.rightBarButtonItems = @[self.navRightButton,self.editRightButton];
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
//    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TabBar Delegates
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    if ([viewController isKindOfClass:[UploadFoldersTableViewController class]]) {
        self.currentFolderController = (UploadFoldersTableViewController *)viewController;
        NSLog(@"current folder controller is -> %@", self.currentFolderController);
        self.currentFolderController.delegate = self;
        self.currentFolderController.doneButton = self.navRightButton;
        self.selectedRootPath = self.currentFolderController.type;
        self.selectedFolderPath = @"";
    }
}

#pragma mark - Folder

-(void)currentFolder:(Folder *)folder root:(NSString *)root{
    NSLog(@"current root -> %@ | folder -> %@",root, folder.fullpath);
    self.selectedFolderPath = folder.fullpath;
    self.selectedRootPath = root;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"tabbar_embed"]) {
        self.tabBarController = (UITabBarController *)[segue destinationViewController];
    }
}


@end

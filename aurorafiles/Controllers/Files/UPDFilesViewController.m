//
//  FilesViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "UPDFilesViewController.h"
#import "FilesTableViewCell.h"
#import "FileDetailViewController.h"
#import "SessionProvider.h"
#import "FileGalleryCollectionViewController.h"
#import "DownloadsTableViewController.h"

#import "GalleryWrapperViewController.h"

#import "Settings.h"
#import "ApiP7.h"
#import "ApiP8.h"
#import "NSStringPunycodeAdditions.h"
#import "SignInViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "STZPullToRefresh.h"
#import "StorageManager.h"
#import "MBProgressHUD.h"
#import "ConnectionProvider.h"
#import "Constants.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CRMediaPickerController.h"
#import <MagicalRecord/MagicalRecord.h>

#import <AFNetworking/AFNetworking.h>
#import "UIApplication+openURL.h"
#import "UploadDownloadProvider.h"


static const int shortcutCreationTexFieldTag = 100;
static const int minimalStringLengthURL = 5;
static const int minimalStringLengthFiles = 1;

@interface UPDFilesViewController () <UITableViewDataSource, UITableViewDelegate,SignControllerDelegate,
        STZPullToRefreshDelegate,NSFetchedResultsControllerDelegate,UISearchBarDelegate,UINavigationControllerDelegate,
        FilesTableViewCellDelegate,
//        NSURLSessionDownloadDelegate,
        CRMediaPickerControllerDelegate,UITextFieldDelegate,
        SWTableViewCellDelegate,UploadDelegate,DownloadDelegate>
{
    UILabel *noDataLabel;
    UIAlertController * alertController;
    UIAlertAction * defaultAction;
}

@property (strong, nonatomic) NSURLSession * session;
@property (strong, nonatomic) NSString * type;
@property (strong, nonatomic) STZPullToRefresh * lineRefreshController;
@property (strong, nonatomic) STZPullToRefreshView *refreshView;
@property (strong, nonatomic) NSManagedObjectContext * defaultMOC;
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) UITextField * folderName;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Folder * folderToOperate;
@property (strong, nonatomic) CRMediaPickerController *pickerController;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) UIRefreshControl *spinnerRefreshController;

@property (strong, nonatomic) SessionProvider *sessionProvider;
@property (strong, nonatomic) StorageManager *storageManager;
@property (strong, nonatomic) UploadDownloadProvider *uploadDownloadManager;
@end

@implementation UPDFilesViewController


#pragma mark - LifeCycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.isCorporate = NO;
    self.isP8 = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.uploadDownloadManager = [UploadDownloadProvider providerWithDefaultMOC:self.defaultMOC
                                                                 storageManager:self.storageManager
                                                       fetchedResultsController:self.fetchedResultsController];
    self.uploadDownloadManager.uploadDelegate = self;
    self.uploadDownloadManager.downloadDelegate = self;

    if (self.folder)
    {

        self.title = self.folder.name;
        UILabel * titleLabel = [[UILabel alloc] init];
        titleLabel.text = self.folder.name;

        self.navigationItem.title = self.folder.name;
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    }
    else
    {
        self.navigationItem.title = [self.type capitalizedString];

    }
    
//    if(!self.isRootFolder){
        [self updateView];
//    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (![Settings version] || ![Settings domain]){
        SignInViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
        signIn.delegate = self;
        [self presentViewController:signIn animated:YES completion:nil];
        return;
    }

    if (![Settings token] && ![Settings password] && ![Settings currentAccount]) {
        SignInViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
        signIn.delegate = self;
        [self presentViewController:signIn animated:YES completion:nil];
        return;
    }

    [self.sessionProvider checkUserAuthorization:^(BOOL authorised, BOOL offline, BOOL isP8, NSError *error) {
        if(error){
            [[ErrorProvider instance]generatePopWithError:error controller:self];
            return;
        }
        self.isP8 = isP8;
        if(authorised && offline){
            [self userWasSigneInOffline];
            return;
        }
        if (!authorised)
        {
//            SignInViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
//            signIn.delegate = self;
//            [self presentViewController:signIn animated:YES completion:nil];
        }
        [[ConnectionProvider sharedInstance]startNotification];
    }];

    [self fetchData];
}

-(void)viewDidDisappear:(BOOL)animated{
    self.fetchedResultsController = nil;
}

#pragma mark -

-(void)setupView{
    
    self.sessionProvider = [SessionProvider sharedManager];
    self.storageManager = [StorageManager sharedManager];
    self.defaultMOC = [self.storageManager.DBProvider defaultMOC];


    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.pickerController = self.pickerController == nil ? [[CRMediaPickerController alloc]init] : self.pickerController;
    self.pickerController.delegate = self;
    self.pickerController.mediaType = (CRMediaPickerControllerMediaTypeImage);
    self.pickerController.sourceType = CRMediaPickerControllerSourceTypePhotoLibrary;
    
    
    self.toolbar.hidden = NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(unlockOnlineButtons) name:CPNotificationConnectionOnline object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(lockOnlineButtons) name:CPNotificationConnectionLost object:nil];
    
    self.navigationController.navigationBar.hidden = NO;
    
    self.refreshView = self.refreshView ? self.refreshView :[[STZPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1.5)];
    [self.view addSubview:self.refreshView];
    self.lineRefreshController = self.lineRefreshController ? self.lineRefreshController : [[STZPullToRefresh alloc] initWithTableView:nil refreshView:self.refreshView tableViewDelegate:self];

    //
    self.isCorporate = [self.type isEqualToString:@"corporate"];
    [[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL * url){
        return [url absoluteString];
    }];
    
    self.signOutButton.tintColor = self.refreshView.progressColor;
    self.editButton.tintColor = self.refreshView.progressColor;

    self.spinnerRefreshController = self.spinnerRefreshController == nil ? [UIRefreshControl new] : self.spinnerRefreshController;
    [self.spinnerRefreshController addTarget:self action:@selector(tableViewPullToRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.spinnerRefreshController];
//    [self.tableView insertSubview:self.spinnerRefreshController atIndex:0];

    self.searchBar.delegate = self;

    [self.tableView registerNib:[UINib nibWithNibName:@"FilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[FilesTableViewCell cellId]];
    
    noDataLabel                  = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    noDataLabel.text             = NSLocalizedString(@"Folder is loading...", @"files refresh title");
    noDataLabel.textColor        = [UIColor lightGrayColor];
    noDataLabel.textAlignment    = NSTextAlignmentCenter;
    noDataLabel.font             = [UIFont fontWithName:@"System" size:22.0f];
    self.tableView.backgroundView = noDataLabel;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewWillLayoutSubviews {
    [self.refreshView setFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 1.5)];
}

- (void)updateView{
    if(![self.view isHidden]) {
        noDataLabel.text = NSLocalizedString(@"Folder is loading...", @"files refresh title");
        [self.lineRefreshController startRefresh];
        [self updateFiles:^() {
            [self stopRefresh];
            [self reloadTableData];
        }];
    }
}

- (void)setFolder:(Folder *)folder
{
    _folder = folder;
    if (_folder)
    {
        self.title = _folder.name;
    }
}

- (void)tableViewPullToRefresh:(UIRefreshControl*)sender
{
    noDataLabel.text             = NSLocalizedString(@"Folder is loading...", @"files refresh title");
    [self updateFiles:^() {
        [self stopRefresh];
        [self reloadTableData];
    }];
}

- (void)fetchData{
    NSError * error = [NSError new];
    if([self.fetchedResultsController performFetch:&error]){
        DDLogDebug(@"✅ fetch success with items -> %@",self.fetchedResultsController.fetchedObjects);
        [self.tableView reloadData];
    }else{
        DDLogError(@"❌ fetch error desc -> %@",error.localizedDescription);
    }
}

- (void)userWasSignedIn
{
    [self updateView];
}

-(void)userWasSigneInOffline
{
    [self lockOnlineButtons];
}

-(void)lockOnlineButtons
{
    [self.tabBarController setSelectedIndex:2];
    for (UITabBarItem *vc in [[self.tabBarController tabBar]items]){
        [vc setEnabled:NO];
    };
}

-(void)unlockOnlineButtons{
    for (UITabBarItem *vc in [[self.tabBarController tabBar]items]){
        [vc setEnabled:YES];
    };
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pullToRefreshDidStart
{
    [self updateFiles:^(){
        [self stopRefresh];
        [self reloadTableData];
    }];
}

#pragma mark - Search Bar

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateSearchResultsWithQuery:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self updateSearchResultsWithQuery:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)updateSearchResultsWithQuery:(NSString*)text
{
    NSArray * existItems = self.fetchedResultsController.fetchedObjects;
    NSMutableArray * indexPathsToDelete = [[NSMutableArray alloc] init];
    
    for (id obj in existItems)
    {
        [indexPathsToDelete addObject:[self.fetchedResultsController indexPathForObject:obj]];
    }
    NSPredicate * predicate;
    if (text && text.length)
    {
         predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND name CONTAINS[cd] %@ AND isP8 = %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath ? self.folder.fullpath : @"",text, [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND wasDeleted = NO AND isP8 = %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath ? self.folder.fullpath : @"", [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
    }
    
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    [self.fetchedResultsController performFetch:nil];
    NSArray * newItems = self.fetchedResultsController.fetchedObjects;
    if (newItems.count == 0){
        noDataLabel.text = NSLocalizedString(@"Files not found..", @"files not found tableView label");
    }

    NSMutableArray * indexPathsToInsert = [[NSMutableArray alloc] init];

    indexPathsToInsert = [[NSMutableArray alloc] init];
    for (id obj in newItems)
    {
        [indexPathsToInsert addObject:[self.fetchedResultsController indexPathForObject:obj]];
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

#pragma mark TableView

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
    
    [self.sessionProvider cancelAllOperations];
    
    if ([object.isFolder boolValue] || [object.mainAction isEqualToString:@"list"])
    {
        [self performSegueWithIdentifier:@"UPDGoToFolderSegue" sender:self];
    }
    else
    {
        if ([object isImageContentType] && ![[object isLink] boolValue])
        {
             [self performSegueWithIdentifier:@"OpenFileGallerySegue" sender:self];
        }
        else if([[object isLink] boolValue]){
            if([object.linkUrl rangeOfString:@"youtube"].location == NSNotFound){
                [[UIApplication sharedApplication] openLink:[NSURL URLWithString:object.linkUrl]];
            }else{
                NSArray *arr = [object.linkUrl componentsSeparatedByString:@"//"];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@",youTubeSheme,[arr lastObject]]];
                if ([[UIApplication sharedApplication]canOpenURL:url]) {
                    [[UIApplication sharedApplication] openLink:url];
                }else{
                    [[UIApplication sharedApplication] openLink:[NSURL URLWithString:object.linkUrl]];
                }
            }
        }
        else
        {
                [self performSegueWithIdentifier:@"OpenFileSegue" sender:self];
        }
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = self.fetchedResultsController.sections[section];
    if ([info numberOfObjects]==0) {
        self.tableView.backgroundView = noDataLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }else{
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    return [info numberOfObjects];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [FilesTableViewCell cellHeight];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * objects = [self.fetchedResultsController fetchedObjects];
    Folder * object = [objects objectAtIndex:indexPath.row];
    FilesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[FilesTableViewCell cellId] forIndexPath:indexPath];
    cell.imageView.image = nil;
    cell.filesDelegate = self;
    cell.delegate = self;
    [cell setupCellForFile:object];
    cell.rightUtilityButtons = [self rightUtilityButtons];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self removeFileByIndexPath:indexPath];
    }
}

- (IBAction)signOut:(id)sender
{
    [self signOut];
}

-(void)signOut{
    [self.sessionProvider logout:^(BOOL succsess, NSError *error) {
        if(error){
            [[ErrorProvider instance]generatePopWithError:error controller:self customCancelAction:nil retryAction:^(UIAlertAction *retryAction) {
                [self signOut];
            }];
            return;
        }
        if (succsess) {
//            SignInViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
//            signIn.delegate = self;
            [self.navigationController popToRootViewControllerAnimated:YES];
//            [self presentViewController:signIn animated:YES completion:^(){}];
            [[NSNotificationCenter defaultCenter]postNotificationName:NNotificationUserSignOut object:nil];
        }
    }];
}


-(void)showDownloadedFiles{
//    [[SessionProvider sharedManager]cancelAllOperations];
    [self performSegueWithIdentifier:@"ShowDownloadsSegue" sender:nil];
}

- (void)updateFiles:(void (^)())completionHandler
{
    if ([Settings domain]) {
        [self.storageManager updateFilesWithType:self.type forFolder:self.folder withCompletion:^(NSInteger *itemsCount, NSError *error){
            if(error){
                [[ErrorProvider instance]generatePopWithError:error controller:self];
                [self stopRefresh];
                return;
            }
            if (completionHandler)
            {
                [self fetchData];
//                id <NSFetchedResultsSectionInfo> info = self.fetchedResultsController.sections[0];
                if (itemsCount==0) {
                    noDataLabel.text = NSLocalizedString(@"Folder is empty", @"files view empty title");
                }
            }
            completionHandler();
        }];
    }
}

- (void)reloadTableData
{
    [self.tableView reloadData];
}

- (void)stopRefresh{
    if([self.spinnerRefreshController isRefreshing]){
        [self.spinnerRefreshController endRefreshing];
    }

    dispatch_async(dispatch_get_main_queue(), ^(){
        [self.lineRefreshController finishRefresh];
    });


}

#pragma mark FilesTableViewCellDelegate

- (void)tableViewCellDownloadAction:(UITableViewCell *)cell
{
    if (![Settings isFirstRun]) {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Download files", @"download popup title")
                                                        message:NSLocalizedString(@"Tapping this icon makes the file available offline. The file will be stored on your device locally. If you want to remove the file from the device, just tap the icon again making it grey and the file won't consume space on your device anymore.", @"download popup message text")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Got it!", @"download popup cancel button title")
                                              otherButtonTitles:nil, nil];
        [alert show];
        [Settings setFirstRun:@"YES"];
    }
    [self tableViewCellDownload:cell];
}

-(void)tableViewCellDownload:(UITableViewCell *)cell{
    Folder * folder = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:cell]];
    if (folder.isDownloaded.boolValue)
    {
        return;
    }
    
    [(FilesTableViewCell*)cell disclosureButton].hidden = NO;
    [(FilesTableViewCell*)cell disclosureButton].enabled = YES;

    [self.uploadDownloadManager startDownloadTaskForFile:folder];
}

-(void)tableViewCell:(UITableViewCell *)cell fileReloadAction:(Folder *)file {
    if (file.isDownloaded.boolValue)
    {
        return;
    }
    [(FilesTableViewCell*)cell disclosureButton].enabled = YES;

    [self.uploadDownloadManager startDownloadTaskForFile:file];
}

-(void)tableViewCellRemoveAction:(UITableViewCell *)cell{
    [self removeFileFromDevice:[self.tableView indexPathForCell:cell]];
}

- (void)indexPathForDownloadingItem:(NSIndexPath *)indexPath {
    FilesTableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell.downloadActivity startAnimating];
    cell.disclosureButton.hidden = YES;
}

- (NSURL*)downloadURL
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"downloads"];
    NSError * error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    if (error)
    {
        DDLogError(@"%@",error);
    }
    return [NSURL URLWithString:filePath];
}

- (void)tableViewCellMoreAction:(UITableViewCell *)cell
{
    Folder * folder = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:cell]];
    self.folderToOperate = folder;
    alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"more action popup title text")
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel text")
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    [alertController addAction:[self renameCurrentFolderAction]];
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    DDLogDebug(@"%s",__PRETTY_FUNCTION__);
}


#pragma mark NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController{
    
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSSortDescriptor *isFolder = [[NSSortDescriptor alloc] initWithKey:@"isFolder" ascending:NO];
    NSSortDescriptor *title = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND wasDeleted = NO AND isP8 = %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath ? self.folder.fullpath : @"", [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
    NSManagedObjectContext *moc = self.defaultMOC;
    NSFetchRequest *req = [Folder getFetchRequestInContext:moc descriptors:@[isFolder, title] predicate:predicate];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:req managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    if ([anObject isKindOfClass:[Folder class]]) {
        Folder *fold = anObject;
        switch (type) {
            case 1:
                DDLogDebug(@"insert fold name is -> %@",fold.name);
                break;
            case 2:
                DDLogDebug(@"deleted fold name is -> %@",fold.name);
                break;
            case 3:
                
                break;
            case 4:
                
                break;
                
            default:
                break;
        }
    }
}
#pragma mark More Actions

- (IBAction)uploadAction:(id)sender {
    [self.pickerController show];
}

- (IBAction)editAction:(id)sender
{
    alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"edit actions title text ")
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel text")
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    self.folderToOperate = _folder;
    if (![self.folder isZippedFile] && ![self.folder isZipArchive]){
        [alertController addAction:[self createFolderAction]];
        [alertController addAction:[self createShortcutAction]];
    }
    
    if (self.folder)
    {
        [alertController addAction:[self renameCurrentFolderAction]];
        [alertController addAction:[self deleteFolderAction]];
    }
    
    [alertController addAction:[self savedFilesAction]];
    [alertController addAction:[self logoutAction]];
    [alertController addAction:cancelAction];
    

    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
        alertController.popoverPresentationController.barButtonItem = self.editButton;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(UIAlertAction *)createShortcutAction{
    UIAlertAction * action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create Shortcut", @"Create shortcut action name")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                [self createShortcut];

            }];
    return action;
}

- (UIAlertAction*)savedFilesAction{
    UIAlertAction* logout = [UIAlertAction actionWithTitle:NSLocalizedString(@"Downloads", @"Downloads action name")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self showDownloadedFiles];
                                                   }];
    return logout;
}

- (UIAlertAction*)logoutAction
{
    UIAlertAction* logout = [UIAlertAction actionWithTitle:NSLocalizedString(@"Logout", @"Logout action name")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                           [self signOut];
                                                   }];
    return logout;
}

-(void)createShortcut{
    alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter URL", @"creating shortcut popup title")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * textField){
        textField.placeholder = NSLocalizedString(@"URL", @"creating shortcut popup textfield placeholder");
        [textField setDelegate:self];
        [textField setTag:shortcutCreationTexFieldTag];

    }];

    void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
        _fetchedResultsController.delegate = nil;
        _fetchedResultsController = nil;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud setMode:MBProgressHUDModeIndeterminate];
        hud.label.text = NSLocalizedString(@"Checking URL...", @"hud cheking url text");
        //        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        //        NSString *urlString = [[(UITextField *)alertController.textFields.lastObject text]stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSString *urlString = [(UITextField *)alertController.textFields.lastObject text].encodedURLString;
        [self.uploadDownloadManager prepareForShortcutUpload:urlString success:^(NSDictionary *shortcutData) {
            NSString * realFileName = shortcutData[kFileName];
            NSString * MIMEType = shortcutData[kMIMEType];
            NSData * fileData = shortcutData[kFileData];
            NSString *resultPath = shortcutData[kResultPath];
            
            [hud setMode:MBProgressHUDModeDeterminate];
            hud.label.text = [NSString stringWithFormat:@"%@ %@", realFileName, NSLocalizedString(@"uploading", @"hud uploading text")];
            [self.uploadDownloadManager uploadFile:fileData
                                          mimeType:MIMEType
                                      toFolderPath:self.folder.fullpath
                                          withName:realFileName
                                       isCorporate:self.isCorporate
                               uploadProgressBlock:^(float progress) {
                                   hud.progress = progress;
                               }
                                        completion:^(BOOL result, NSError *error) {
                                            if (error){
                                                [hud hideAnimated:YES];
                                                [[ErrorProvider instance]generatePopWithError:error controller:self
                                                                           customCancelAction:nil
                                                                                  retryAction:actionBlock];
                                                return;
                                            }
                                            if (result) {
                                                [hud setMode:MBProgressHUDModeIndeterminate];
                                                hud.label.text = NSLocalizedString(@"Updating files...", @"hud updating files text");
                                                [self updateFiles:^(){
                                                    [hud hideAnimated:YES];
                                                    [self reloadTableData];
                                                    [self removeShortcutFromDeviceHDD:resultPath];
                                                }];
                                            }else{
                                                [hud hideAnimated:YES];
                                                [self removeShortcutFromDeviceHDD:resultPath];
                                            }
                                        }];
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                [[ErrorProvider instance]generatePopWithError:error controller:self
                                           customCancelAction:nil
                                                  retryAction:actionBlock];
            });
        }];

    };
    defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create", @"") style:UIAlertActionStyleDefault handler:actionBlock];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel text")
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action){

    }];
    [alertController addAction:defaultAction];
    [defaultAction setEnabled:NO];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)removeShortcutFromDeviceHDD:(NSString *)path{
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        return NO;
    }else{
        return [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
}

- (void)CRMediaPickerController:(CRMediaPickerController *)mediaPickerController didFinishPickingAsset:(ALAsset *)asset error:(NSError *)error {

    NSDictionary * fileDataDictionary = [self.uploadDownloadManager prepareFileFromAsset:asset error:error];
    NSString * realFileName = fileDataDictionary[kFileName];
    NSString * MIMEType = fileDataDictionary[kMIMEType];
    NSData * fileData = fileDataDictionary[kFileData];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeDeterminate;
    hud.label.text = [NSString stringWithFormat:@"%@ %@",realFileName, NSLocalizedString(@"uploading", @"hud uploading text")];

    [self.uploadDownloadManager uploadFile:fileData
                                   mimeType:MIMEType
                               toFolderPath:self.folder.fullpath
                                   withName:realFileName
                                isCorporate:self.isCorporate
                        uploadProgressBlock:^(float progress) {
                            hud.progress = progress;
                        } completion:^(BOOL result, NSError *error) {
                            if(error){
                                [hud hideAnimated:YES];
                                [[ErrorProvider instance]generatePopWithError:error controller:self customCancelAction:nil retryAction:^(UIAlertAction *retryAction) {
                                    [self uploadAction:nil];
                                }];
                                return;
                            }
                if (result) {
                    [self updateFiles:^(){
                        [hud hideAnimated:YES];
                        [self reloadTableData];
                    }];
                }else{
                    [hud hideAnimated:YES];
                }
            }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
//    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
//    
//    NSURL *urlFile = [info objectForKey:UIImagePickerControllerReferenceURL];
//    [picker dismissViewControllerAnimated:YES completion:nil];
//
//    
//    NSString *fileName = [NSString stringWithFormat:@"%@_%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],[[urlFile path] lastPathComponent]];
//    
//    
////  NSData * data = [NSData dataWithContentsOfURL:[info objectForKey:UIImagePickerControllerReferenceURL]];
//    NSData * data = UIImagePNGRepresentation(image);
//    NSString * path = self.isCorporate ? @"corporate" : @"personal";
//    if (self.folder.fullpath)
//    {
//        path = [NSString stringWithFormat:@"%@%@",path,self.folder.fullpath];
//    }
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    [[ApiP7 sharedInstance] putFile:data toFolderPath:path withName:fileName completion:^(NSDictionary * response){
//        DDLogDebug(@"%@",response);
//        [self updateFiles:^(){
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//        }];
//    }];
}

- (UIAlertAction*)deleteFolderAction
{
    
    void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
        Folder * object = self.folderToOperate;
        [self.storageManager deleteItem:object controller:self isCorporate:self.isCorporate completion:^(BOOL succsess, NSError *error) {
            if(error){
                //                                                                      [hud hideAnimated:YES];
                [[ErrorProvider instance]generatePopWithError:error
                                                   controller:self
                                           customCancelAction:nil
                                                  retryAction:actionBlock];
                return;
            }
            if (succsess) {
                DDLogDebug(@"file named %@ successfuly removed", object.name);
                [self updateFiles:^(){
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            }else{
                DDLogDebug(@"file named %@ hasn't been removed", object.name);
            }
        }];
    };
    UIAlertAction * deleteFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"delete action title text")
                                                            style:UIAlertActionStyleDestructive
                                                          handler:actionBlock];
    
    return deleteFolder;
}

- (UIAlertAction*)renameCurrentFolderAction
{
    NSString * text = [self.folderToOperate isEqual:self.folder] ? NSLocalizedString(@"Rename Current Folder", @"rename folder action title text") : NSLocalizedString(@"Rename", @"rename file action title text");
    UIAlertAction* renameFolder = [UIAlertAction actionWithTitle:text style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"rename popup title text")
                                                                                                                                    message:nil
                                                                                                                             preferredStyle:UIAlertControllerStyleAlert];
                                                             [alertController addTextFieldWithConfigurationHandler:^(UITextField * textField){
                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"rename popup textField placeholder text");
                                                                 textField.text = _folderToOperate.name;
                                                                 self.folderName = textField;
                                                                 [textField setDelegate:self];
                                                             }];
                                                             
                                                             void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
                                                                 if (!_folderToOperate)
                                                                 {
                                                                     return ;
                                                                 }
                                                                 _fetchedResultsController.delegate = nil;
                                                                 _fetchedResultsController = nil;
                                                                 
                                                                 [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                                 
                                                                 [self.storageManager  renameOperation:_folderToOperate withNewName:self.folderName.text withCompletion:^(Folder * updatedFile, NSError *error) {
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                         
                                                                     });
                                                                     if(error){
                                                                         [[ErrorProvider instance]generatePopWithError:error controller:self
                                                                                                    customCancelAction:nil
                                                                                                           retryAction:actionBlock];
                                                                         return;
                                                                     }
                                                                     if (updatedFile && !updatedFile.isFault) {
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             self.folderToOperate = updatedFile;
                                                                             self.folder = updatedFile;
                                                                             self.title = updatedFile.name;
                                                                             [self fetchData];
                                                                         });
                                                                     }else{
                                                                         
                                                                     }
                                                                 }];
                                                             };
                                                             
                                                             defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"save action title text")
                                                                                                                      style:UIAlertActionStyleDefault
                                                                                                                    handler:actionBlock];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel text")
                                                                                                                     style:UIAlertActionStyleCancel
                                                                                                                   handler:^(UIAlertAction * action){
                                                                 
                                                             }];
                                                             [alertController addAction:defaultAction];
                                                             [defaultAction setEnabled:NO];
                                                             [alertController addAction:cancelAction];
                                                             [self presentViewController:alertController animated:YES completion:nil];
                                                         }];
    return renameFolder;

}

- (UIAlertAction*)createFolderAction
{
    UIAlertAction* createFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create Folder", @"") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                             [alertController addTextFieldWithConfigurationHandler:^(UITextField * textField){
                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 
                                                                 self.folderName = textField;
                                                                 [textField setDelegate:self];
                                                             }];
                                                             void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
                                                                 [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                                 [self.storageManager createFolderWithName:self.folderName.text isCorporate:self.isCorporate andPath:self.folder.fullpath completion:^(BOOL success, NSError *error) {
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                     });
                                                                     if(error){
                                                                         [[ErrorProvider instance]generatePopWithError:error controller:self
                                                                                                    customCancelAction:nil
                                                                                                           retryAction:actionBlock];
                                                                         return;
                                                                     }
                                                                     if (success) {
                                                                         
                                                                         [self updateFiles:^(){
                                                                             [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                             [self.tableView reloadData];
                                                                         }];
                                                                     }
                                                                 }];
                                                             };
                                                            
                                                             defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create", @"") style:UIAlertActionStyleDefault handler:actionBlock];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel text") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                                                                 
                                                             }];
                                                             [alertController addAction:defaultAction];
                                                             [defaultAction setEnabled:NO];
                                                             [alertController addAction:cancelAction];
                                                             [self presentViewController:alertController animated:YES completion:nil];
                                                         }];
    return createFolder;
}

#pragma mark - TextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    int minimalStringLength = textField.tag == shortcutCreationTexFieldTag ? minimalStringLengthURL:minimalStringLengthFiles;
    [defaultAction setEnabled:text.length>=minimalStringLength];
    return YES;
}

#pragma mark - SWTableViewCell Delegate

- (NSArray *)rightUtilityButtons{
    NSMutableArray *buttons = [NSMutableArray new];
    [buttons sw_addUtilityButtonWithColor:[UIColor grayColor] title:NSLocalizedString(@"Rename", @"cell Rename title")];
    [buttons sw_addUtilityButtonWithColor:[UIColor redColor] title:NSLocalizedString(@"Delete", @"cell Delete title")];
    return buttons;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index{
    
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index{
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    [self.fetchedResultsController performFetch:nil];
    Folder * folder = [self.fetchedResultsController objectAtIndexPath:cellIndexPath];
    switch (index) {
        case 0:{
            DDLogDebug(@"Rename button pressed");
            alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"rename popup title text")
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleAlert];
            [alertController addTextFieldWithConfigurationHandler:^(UITextField * textField){
                textField.placeholder = NSLocalizedString(@"Folder Name", @"rename popup textField placeholder text");
                textField.text = folder.name;
                self.folderName = textField;
                [textField setDelegate:self];
            }];
            
            void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
                if (!folder)
                {
                    return ;
                }
                _fetchedResultsController.delegate = nil;
                _fetchedResultsController = nil;
                
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                [self.storageManager  renameOperation:folder withNewName:self.folderName.text withCompletion:^(Folder * updatedFile, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    });
                    if(error){
                        [[ErrorProvider instance]generatePopWithError:error
                                                           controller:self
                                                   customCancelAction:nil
                                                          retryAction:actionBlock];
                        return;
                    }
                    if(updatedFile && !updatedFile.isFault){
                        [self updateFiles:^(){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                [self.tableView reloadData];
                            });
                        }];
                    }
                }];
            };
            defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"save action title text")
                                                     style:UIAlertActionStyleDefault
                                                   handler:actionBlock];
            
            UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel text")
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * action){
                                                                      
                                                                  }];
            [alertController addAction:defaultAction];
            [defaultAction setEnabled:NO];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:nil];

        }
            break;
        case 1:{
            DDLogDebug(@"Delete button pressed");
            [self.storageManager deleteItem:folder controller:self isCorporate:self.isCorporate completion:^(BOOL succsess, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
                if(error){
                    return;
                }
                if (succsess) {
                    DDLogDebug(@"file named %@ successfuly removed", folder.name);
                    [self updateFiles:^(){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                            [self.tableView reloadData];
                        });
                    }];
                }else{
                    DDLogDebug(@"file named %@ hasn't been removed", folder.name);
                }
            }];
        }
            break;
        default:
            DDLogDebug(@"default");
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state{
    
}

#pragma mark - Utility Methods



-(void)removeFileFromDevice:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * path = [object localPath];
    
    NSFileManager * manager = [NSFileManager defaultManager];
    NSError * error;
    [manager removeItemAtURL:[NSURL fileURLWithPath:path] error:&error];
    if (self.isP8){
        [self.storageManager removeSavedFilesForItem:object];
    }
    object.isDownloaded = @NO;
    
    if (error)
    {
        DDLogError(@"%@",[error userInfo]);
    }
    
    [self.defaultMOC  save:nil];
}

-(void)removeFileByIndexPath:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    object.wasDeleted = @YES;
    [self removeItem:object];
}

- (void)removeItem:(Folder *)object{
    [self.storageManager deleteItem:object controller:self isCorporate:self.isCorporate completion:^(BOOL succsess, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        if(error){
            [[ErrorProvider instance]generatePopWithError:error
                                               controller:self
                                       customCancelAction:nil
                                              retryAction:^(UIAlertAction *retryAction) {
                                                  [self removeItem:object];
                                              }];
            return;
        }
        if (succsess) {
            DDLogDebug(@"file named %@ successfuly removed", object.name);
            [self.defaultMOC  save:nil];
        }else{
            DDLogDebug(@"file named %@ hasn't been removed", object.name);
        }
    }];

}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"UPDGoToFolderSegue"])
    {
        Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        UPDFilesViewController * vc = [segue destinationViewController];
        vc.folder = object;
        vc.isCorporate = self.isCorporate;
    }
    if ([segue.identifier isEqualToString:@"OpenFileSegue"])
    {
        Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        FileDetailViewController * vc = [segue destinationViewController];
        NSString *viewLink = nil;
        if ([[Settings version]isEqualToString:@"P8"]) {
            viewLink = [NSString stringWithFormat:@"%@%@/%@",[Settings domainScheme],[Settings domain], [object viewUrl]];
            vc.isP8 = YES;
        }else{
            viewLink = [NSString stringWithFormat:@"%@%@/?/Raw/FilesView/%@/%@/0/hash/%@",[Settings domainScheme],[Settings domain],[Settings currentAccount],[object folderHash],[Settings authToken]];
            if (object.isDownloaded.boolValue)
            {
                viewLink = [[[self downloadURL] URLByAppendingPathComponent:object.name] absoluteString];
            }
            vc.isP8 = NO;
        }
        vc.viewLink = viewLink;
        vc.object = object;
        vc.type = self.type;
    }
    if ([segue.identifier isEqualToString:@"OpenFileGallerySegue"])
    {
        Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        
        NSFetchRequest * fetchImageFilesItemsRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchImageFilesItemsRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        fetchImageFilesItemsRequest.predicate = [NSPredicate predicateWithFormat:@"parentPath = %@ AND isFolder == NO AND contentType IN (%@) AND type == %@ AND isP8 = %@",self.folder.fullpath ? self.folder.fullpath : @"",[Folder imageContentTypes],self.type, [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
        NSError * error = [NSError new];
        NSArray *items = [[[[StorageManager sharedManager] DBProvider]defaultMOC] executeFetchRequest:fetchImageFilesItemsRequest error:&error];
        
        GalleryWrapperViewController * vc = [segue destinationViewController];
        vc.itemsList = items;
        vc.initialPageIndex = [items indexOfObject:object];
    }
    
    if([segue.identifier isEqualToString:@"ShowDownloadsSegue"]){
        DownloadsTableViewController *vc = [segue destinationViewController];
        vc.loadType = loadTypeView;
    }
}
@end

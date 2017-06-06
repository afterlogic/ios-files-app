//
//  UploadFoldersTableViewController.m
//  aurorafiles
//
//  Created by Cheshire on 28.09.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "FilesTableViewCell.h"
#import "SessionProvider.h"
#import "Settings.h"
#import "ApiP7.h"
#import "UIImage+Aurora.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "StorageManager.h"
#import "ConnectionProvider.h"
#import "Constants.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UploadFoldersTableViewController.h"
#import <BugfenderSDK/BugfenderSDK.h>
#import "ApiP8.h"
#import "STZPullToRefresh.h"
#import "AuroraHUD.h"
#import "MBProgressHUD.h"

static const int minimalStringLengthFiles = 1;

@interface UploadFoldersTableViewController () <UITableViewDataSource, UITableViewDelegate,STZPullToRefreshDelegate,NSFetchedResultsControllerDelegate,
UISearchBarDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, FilesTableViewCellDelegate,
NSURLSessionDownloadDelegate,SWTableViewCellDelegate>{
    
    UIAlertController * alertController;
    UIAlertAction * defaultAction;
}

@property (strong, nonatomic) NSURLSession * session;
@property (strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) UITextField * folderName;
@property (strong, nonatomic) Folder * folderToOperate;
@property (strong, nonatomic) Folder * folderToNavigate;
@property (weak, nonatomic) IBOutlet UIRefreshControl *refreshController;
@property (strong, nonatomic) STZPullToRefresh * lineRefreshController;

@end

@implementation UploadFoldersTableViewController

- (void)loadView{
//    DDLogDebug(@"self -> %@",self);
    [super loadView];
//    DDLogDebug(@"self after super load -> %@",self);
}

- (void)awakeFromNib{
    [super awakeFromNib];
    self.isCorporate = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(unlockOnlineButtons) name:CPNotificationConnectionOnline object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(lockOnlineButtons) name:CPNotificationConnectionLost object:nil];
    
    self.managedObjectContext = [[[StorageManager sharedManager] DBProvider]defaultMOC];
    
    self.isCorporate = [self.type isEqualToString:@"corporate"];
    
    [[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL * url){
        return [url absoluteString];
    }];

    STZPullToRefreshView *refreshView = [[STZPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1.5)];
    [self.view addSubview:refreshView];
    self.lineRefreshController = [[STZPullToRefresh alloc] initWithTableView:nil refreshView:refreshView tableViewDelegate:self];
    
    [self.refreshController addTarget:self action:@selector(tableViewPullToRefresh:) forControlEvents:UIControlEventValueChanged];
    self.searchBar.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[FilesTableViewCell cellId]];
    [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 50, self.tableView.contentInset.right)];

}

- (void)startUpdate{
    [self.lineRefreshController startRefresh];
    [self updateFiles:^{
        [self.lineRefreshController finishRefresh];
        [self.refreshController endRefreshing];
    }];
}

- (void)setFolder:(Folder *)folder
{
    _folder = folder;
    if (folder)
    {
        self.title = folder.name;
        [self.delegate currentFolder:self.folder root:self.type];
    }
}

-(void)setControllersStack:(NSMutableArray<UploadFoldersTableViewController *> *)controllersStack{
    _controllersStack = controllersStack;
    if (controllersStack && controllersStack.count > 0) {
        NSMutableArray *curentControllersStack = [self.navigationController viewControllers].mutableCopy;
        for (UploadFoldersTableViewController *vc in controllersStack) {
            vc.doneButton = self.doneButton;
            vc.editButton = self.editButton;
        };
        DDLogDebug(@"curentControllersStack %@",curentControllersStack);
        for (UploadFoldersTableViewController* vc in controllersStack) {
                [self.navigationController pushViewController:vc animated:NO];
        }
        
    }
}

- (void)tableViewPullToRefresh:(UIRefreshControl*)sender
{
//    [self updateFiles:^(){
//        [self.refreshController endRefreshing];
//    }];

    [self startUpdate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.folder)
    {
        
        self.title = self.folder.name;
        UILabel * titleLabel = [[UILabel alloc] init];
        titleLabel.text = self.folder.name;
        
        self.navigationItem.title = self.folder.name;
        self.navigationItem.leftBarButtonItem = self.backButton;
        self.navigationItem.rightBarButtonItems = @[self.doneButton, self.editButton];
        
        [self.delegate currentFolder:self.folder root:self.type];
        
    }
    else
    {
        self.navigationItem.title = [self.type capitalizedString];
        self.navigationItem.rightBarButtonItems = @[self.doneButton,self.editButton];
        
    }
    NSError * error = nil;
    [self.fetchedResultsController performFetch:&error];

    [self startUpdate];
}

- (void)userWasSignedIn{

}

-(void)userWasSigneInOffline{

}

-(void)lockOnlineButtons{

}

-(void)unlockOnlineButtons{

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[SessionProvider sharedManager] checkUserAuthorization:^(BOOL authorised, BOOL offline,BOOL isP8,NSError* error){
        if(authorised && offline){
            [self userWasSigneInOffline];
            return;
        }
        [[ConnectionProvider sharedInstance]startNotification];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)pullToRefreshDidStart{
    [self startUpdate];
}



-(void)setDelegate:(id<FolderDelegate>)delegate{
    if (delegate) {
        _delegate = delegate;
    }
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
        predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND name CONTAINS[cd] %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath,text];
        
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath];
    }
    
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    NSError * error;
    [self.fetchedResultsController performFetch:&error];
    NSArray * newItems = self.fetchedResultsController.fetchedObjects;
    NSMutableArray * indexPathsToInsert = [[NSMutableArray alloc] init];
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
    if ([object.isFolder boolValue])
    {
        self.folderToNavigate = object;
        [self performSegueWithIdentifier:@"GoToFolderSegue" sender:self];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = self.fetchedResultsController.sections[section];
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
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    FilesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[FilesTableViewCell cellId] forIndexPath:indexPath];
    cell.imageView.image = nil;
    cell.filesDelegate = self;
    cell.delegate = self;
    cell.rightUtilityButtons = [self rightUtilityButtons];
    [cell setupCellForFile:object];
    [cell.disclosureButton setEnabled:NO];
    [cell.disclosureButton setHidden:YES];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        
        [self removeFileFromCloud:indexPath];
    }
}

- (void)updateFiles:(void (^)())handler
{
    [[StorageManager sharedManager] updateFilesWithType:self.isCorporate ? @"corporate" : @"personal" forFolder:self.folder withCompletion:^(NSInteger *itemsCount,NSError* error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        if(error){
            [[ErrorProvider instance]generatePopWithError:error controller:self];
            [self.lineRefreshController finishRefresh];
            [self.refreshController endRefreshing];
            return;
        }
        if (handler)
        {
            handler();
            [self reloadTableData];
        }
    }];
}

- (void)updateFilesWithSubsequentTransitionFromFolder:(Folder *)folder handler:(void (^)())handler{
    [[StorageManager sharedManager] updateFilesWithType:self.isCorporate ? @"corporate" : @"personal" forFolder:self.folder withCompletion:^(NSInteger *itemsCount,NSError* error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        if(error){
            [[ErrorProvider instance]generatePopWithError:error controller:self];
            return;
        }
        if (handler)
        {
            handler();
            [self reloadTableData];
            
            [self.fetchedResultsController performFetch:nil];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@ AND isFolder == YES", self.folderName.text];
            NSArray *filteredArray = [[self.fetchedResultsController fetchedObjects]filteredArrayUsingPredicate:predicate];
            DDLogDebug(@"%@ fetched folders after Folder Create Operations -> ", filteredArray);
            if (filteredArray.count > 0){
                self.folderToNavigate = [filteredArray lastObject];
                [self performSegueWithIdentifier:@"GoToFolderSegue" sender:self];
            }else{
                BOOL isP8 = [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]];
                NSDictionary *itemRef = [self generateSimpleItemRefUsingParentFolder:folder];
                self.folderToNavigate = [Folder createFolderFromRepresentation:itemRef type:isP8 parrentPath:folder.fullpath ? folder.fullpath : @"" InContext:self.managedObjectContext];
                [self performSegueWithIdentifier:@"GoToFolderSegue" sender:self];
            }
            

        }
    }];
}

- (NSDictionary *)generateSimpleItemRefUsingParentFolder:(Folder *)folder{
    return @{@"Name":self.folderName.text,
             @"Id":self.folderName.text,
             @"Path":folder.fullpath ? folder.fullpath : @"",
             @"IsLink":@'0',
             @"IsFolder":@'1',
             @"FullPath":[NSString stringWithFormat:@"%@/%@",folder.fullpath,self.folderName.text],
             @"Type":self.isCorporate ? @"corporate": @"personal"
             };
}

- (void)reloadTableData
{
    [self.tableView reloadData];
}

#pragma mark FilesTableViewCellDelegate

- (void)tableViewCellDownloadAction:(UITableViewCell *)cell
{
    Folder * folder = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:cell]];
    if (folder.isDownloaded.boolValue)
    {
        return;
    }
    
    [(FilesTableViewCell*)cell disclosureButton].hidden = YES;
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.afterlogic.files"];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    BFLog(@"%@",[NSURL URLWithString:[folder downloadLink]]);
    NSURLSessionDownloadTask * downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:[folder downloadLink]]];
    folder.downloadIdentifier = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
    NSError * error;
    [folder.managedObjectContext save:&error];
    [downloadTask resume];
    
}

-(void)tableViewCellRemoveAction:(UITableViewCell *)cell{
    [self removeFileFromDevice:[self.tableView indexPathForCell:cell]];
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
        NSFetchRequest * fetchDownloadRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchDownloadRequest.predicate = [NSPredicate predicateWithFormat:@"downloadIdentifier = %@ AND isDownloaded = NO",[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]];
        fetchDownloadRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"downloadIdentifier" ascending:YES]];
        fetchDownloadRequest.fetchLimit = 1;
        NSError * error;
        Folder * file = [[self.managedObjectContext executeFetchRequest:fetchDownloadRequest error:&error] firstObject];
        if (file)
        {
            NSIndexPath * indxPath = [self.fetchedResultsController indexPathForObject:file];
            if (indxPath)
            {
                FilesTableViewCell * cell = [self.tableView cellForRowAtIndexPath:indxPath];
                
                [cell.downloadActivity startAnimating];
                cell.disclosureButton.hidden = YES;
            }
            
        }
    }];
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
        BFLog(@"%@",error);
    }
    return [NSURL URLWithString:filePath];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSError * error;
    
    NSFetchRequest * fetchDownloadRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
    fetchDownloadRequest.predicate = [NSPredicate predicateWithFormat:@"downloadIdentifier = %@ AND isDownloaded = NO",[NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier]];
    
    fetchDownloadRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"downloadIdentifier" ascending:YES]];
    fetchDownloadRequest.fetchLimit = 1;
    Folder * file = [[self.managedObjectContext executeFetchRequest:fetchDownloadRequest error:&error] firstObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *destinationFilename = file.name;
    
    NSURL *destinationURL = [[self downloadURL] URLByAppendingPathComponent:destinationFilename];
    destinationURL = [NSURL fileURLWithPath:[destinationURL absoluteString]];
    BFLog(@"%@",[self downloadURL]);
    BFLog(@"%@",destinationURL);
    
    if ([fileManager fileExistsAtPath:[destinationURL path]])
    {
        [fileManager removeItemAtURL:destinationURL error:nil];
    }
    
    BOOL success = [fileManager copyItemAtURL:location
                                        toURL:destinationURL
                                        error:&error];
    
    
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
        
        if (!success)
        {
            BFLog(@"failed to download %@", [error userInfo]);
        }
        
        file.downloadIdentifier = [NSNumber numberWithInt:-1];
        file.isDownloaded = [NSNumber numberWithBool:success];
        if(success)
        {
            file.downloadedName = destinationFilename;
        }
        NSError * error;
        [file.managedObjectContext save:&error];
    }];
    
}

- (void)tableViewCellMoreAction:(UITableViewCell *)cell
{
    Folder * folder = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:cell]];
    self.folderToOperate = folder;
    alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    BFLog(@"%s",__PRETTY_FUNCTION__);
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
                [[StorageManager sharedManager] renameOperation:folder withNewName:self.folderName.text withCompletion:^(Folder *updatedFile,NSError* error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    });
                    if(error){
                        [[ErrorProvider instance]generatePopWithError:error controller:self
                                                   customCancelAction:nil
                                                          retryAction:actionBlock];
                        return;
                    }
                    [self updateFiles:^(){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self.tableView reloadData];
                        });
                    }];
                    
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
            [[StorageManager sharedManager] deleteItem:folder controller:self isCorporate:self.isCorporate completion:^(BOOL succsess,NSError* error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
                if(error){
                    return;
                }
                if (succsess) {
                    DDLogDebug(@"file named %@ successfuly removed", folder.name);
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [MBProgressHUD hideHUDForView:self.view animated:YES];
//                    });
                    [self updateFiles:^(){
                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                            [self.tableView reloadData];
                        });
                    }];
                }else{
                    DDLogDebug(@"file named %@ hasn't been removed", folder.name);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    });
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


#pragma mark - Help Methods

-(void)removeFileFromDevice:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    NSString * path = [[[object localURL] URLByAppendingPathComponent:object.name] absoluteString];
    NSString * path = [object localURL].absoluteString;
    NSFileManager * manager = [NSFileManager defaultManager];
    NSError * error;
    [manager removeItemAtURL:[NSURL fileURLWithPath:path] error:&error];
    object.isDownloaded = @NO;
    
    if (error)
    {
        BFLog(@"%@",[error userInfo]);
    }
    
    [self.managedObjectContext save:nil];
    
}

-(void)removeFileFromCloud:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [[StorageManager sharedManager]deleteItem:object controller:self isCorporate:self.isCorporate completion:^(BOOL succsess,NSError* error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        if(error){
            return;
        }
        if (succsess) {
            DDLogDebug(@"file named %@ successfuly removed", object.name);
            [self.managedObjectContext  save:nil];
        }else{
            DDLogDebug(@"file named %@ hasn't been removed", object.name);
        }
    }];
}


#pragma mark NSFetchedResultsController

- (NSFetchedResultsController*)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSSortDescriptor *isFolder = [[NSSortDescriptor alloc]
                                  initWithKey:@"isFolder" ascending:NO];
    NSSortDescriptor *title = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND wasDeleted= NO AND isP8 = %@ AND isFolder = YES",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath ? self.folder.fullpath : @"", [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
    NSError * error;

    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *req = [Folder getFetchRequestInContext:moc descriptors:@[isFolder, title] predicate:predicate];
    [req setReturnsObjectsAsFaults:NO];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:req managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    [_fetchedResultsController performFetch:&error];
    
    return _fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}
#pragma mark More Actions

-(void)backAction:(id)sender{
    [self.navigationController popViewControllerAnimated:NO];
}


#pragma mark Edit Menu Actions

- (IBAction)editAction:(id)sender
{
    alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    self.folderToOperate = self.folder;
    [alertController addAction:[self createFolderAction]];
    if (self.folder)
    {
        [alertController addAction:[self renameCurrentFolderAction]];
    }
    [alertController addAction:cancelAction];
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
        alertController.popoverPresentationController.barButtonItem = self.editButton;
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

- (UIAlertAction*)deleteFolderAction
{
    UIAlertAction * deleteFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action){
        Folder * object = self.folderToOperate;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[StorageManager sharedManager]deleteItem:object controller:self isCorporate:self.isCorporate completion:^(BOOL succsess,NSError* error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            if(error){
                return;
            }
            if(succsess){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
                [self updateFiles:^(){
                    [self.tableView reloadData];
                }];
            }
        }];
    }];
    
    return deleteFolder;
}

- (UIAlertAction*)renameCurrentFolderAction
{
    NSString * text = [self.folderToOperate isEqual:self.folder] ? NSLocalizedString(@"Rename Current Folder", @"") : NSLocalizedString(@"Rename", @"");
    UIAlertAction* renameFolder = [UIAlertAction actionWithTitle:text style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                             [alertController addTextFieldWithConfigurationHandler:^(UITextField * textField){
                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 textField.text = self.folderToOperate.name;
                                                                 self.folderName = textField;
                                                                 [textField setDelegate:self];
                                                             }];
                                                             void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
                                                                 if (!self.folderToOperate)
                                                                 {
                                                                     return ;
                                                                 }
                                                                 _fetchedResultsController.delegate = nil;
                                                                 _fetchedResultsController = nil;
                                                                 [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                                 [[StorageManager sharedManager] renameOperation:self.folderToOperate withNewName:self.folderName.text withCompletion:^(Folder * updatedFile,NSError* error) {
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
                                                                     self.folderToOperate = updatedFile;
                                                                     self.folder = updatedFile;
                                                                     self.title = updatedFile.name;
                                                                     //                                                                     NSError * error = nil;
                                                                     [self.fetchedResultsController performFetch:&error];
                                                                     if (error)
                                                                     {
                                                                         BFLog(@"%@",[error userInfo]);
                                                                     }
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                     });
                                                                     [self updateFiles:^(){
                                                                         [self.tableView reloadData];
                                                                     }];
                                                                     
                                                                 }];
                                                             };
                                                             defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:actionBlock];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                                                                 
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
                                                             
                                                             __weak typeof (self)weakSelf = self;
                                                             void (^__block actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action){
                                                                 [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                                 [[StorageManager sharedManager]createFolderWithName:weakSelf.folderName.text isCorporate:weakSelf.isCorporate andPath:weakSelf.folder.fullpath completion:^(BOOL success,NSError* error) {
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
                                                                     if (success) {
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                         });
                                                                         [self updateFilesWithSubsequentTransitionFromFolder:weakSelf.folder handler:^{
                                                                             
                                                                         }];
                                                                     }else{
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                         });
                                                                         [self updateFiles:^{
                                                                             
                                                                         }];
                                                                     }
                                                                 }];
                                                             };
                                                             defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create", @"") style:UIAlertActionStyleDefault handler:actionBlock];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                                                                 
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
    int minimalStringLength = minimalStringLengthFiles;
    
    NSRange charRange = [text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*|\":<>?/\\"]];
    if (charRange.location != NSNotFound) {
        return NO;
    }
    [defaultAction setEnabled:text.length>=minimalStringLength];
    return YES;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GoToFolderSegue"])
    {
        Folder * object = self.folderToNavigate;
        UploadFoldersTableViewController * vc = [segue destinationViewController];
        vc.delegate = self.delegate;
        vc.folder = object;
        vc.isCorporate = self.isCorporate;
        vc.doneButton = self.doneButton;
        [self.foldersStack removeObject:[self.foldersStack lastObject]];
        vc.foldersStack = self.foldersStack;
    }
}

- (UIImage *)snapshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [[UIScreen mainScreen] scale]);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

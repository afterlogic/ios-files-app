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
#import "SignInViewController.h"
#import "UIImage+Aurora.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "STZPullToRefresh.h"
#import "StorageManager.h"
#import "MBProgressHUD.h"
#import "ConnectionProvider.h"
#import "Constants.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CRMediaPickerController.h"
#import <MagicalRecord/MagicalRecord.h>

@interface UPDFilesViewController () <UITableViewDataSource, UITableViewDelegate,SignControllerDelegate,STZPullToRefreshDelegate,NSFetchedResultsControllerDelegate,UISearchBarDelegate,UINavigationControllerDelegate, FilesTableViewCellDelegate,NSURLSessionDownloadDelegate, CRMediaPickerControllerDelegate>{
    UILabel *noDataLabel;
}

@property (strong, nonatomic) NSURLSession * session;
@property (strong, nonatomic) NSString * type;
@property (strong, nonatomic) STZPullToRefresh * pullToRefresh;
@property (strong, nonatomic) NSManagedObjectContext * defaultMOC;
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) UITextField * folderName;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Folder * folderToOperate;
@property (strong, nonatomic) Folder * downloadedItem;
@property (strong, nonatomic) CRMediaPickerController *pickerController;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSDictionary * folderMOC;

@property (strong, nonatomic) SessionProvider *sessionProvider;
@property (strong, nonatomic) StorageManager *storageManager;
@end

@implementation UPDFilesViewController

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

    // Do any additional setup after loading the view.
}

-(void)setupView{
    
    self.sessionProvider = [SessionProvider sharedManager];
    self.storageManager = [StorageManager sharedManager];
    self.defaultMOC = [self.storageManager.DBProvider defaultMOC];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.pickerController = [[CRMediaPickerController alloc]init];
    self.pickerController.delegate = self;
    self.pickerController.mediaType = (CRMediaPickerControllerMediaTypeImage);
    self.pickerController.sourceType = CRMediaPickerControllerSourceTypePhotoLibrary;
    
    
    self.toolbar.hidden = NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(unlockOnlineButtons) name:CPNotificationConnectionOnline object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(lockOnlineButtons) name:CPNotificationConnectionLost object:nil];
    
    self.navigationController.navigationBar.hidden = NO;
    
    STZPullToRefreshView *refreshView = [[STZPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1.5)];
    [self.view addSubview:refreshView];
    
    //    // Setup PullToRefresh
    self.pullToRefresh = [[STZPullToRefresh alloc] initWithTableView:nil
                                                         refreshView:refreshView
                                                   tableViewDelegate:self];
    //
    self.isCorporate = [self.type isEqualToString:@"corporate"];
    [[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL * url){
        return [url absoluteString];
    }];
    
    self.signOutButton.tintColor = refreshView.progressColor;
    self.editButton.tintColor = refreshView.progressColor;
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.refreshControl addTarget:self action:@selector(tableViewPullToRefresh:) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshControl;
    self.searchBar.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[FilesTableViewCell cellId]];
    
    noDataLabel                  = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    noDataLabel.text             = @"Folder is loading...";
    noDataLabel.textColor        = [UIColor lightGrayColor];
    noDataLabel.textAlignment    = NSTextAlignmentCenter;
    noDataLabel.font             = [UIFont fontWithName:@"System" size:22.0f];
    self.tableView.backgroundView = noDataLabel;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self updateView];
}

- (void)updateView{
    [self.pullToRefresh startRefresh];
    [self updateFiles:^() {
        [self.pullToRefresh finishRefresh];
        [self reloadTableData];
    }];
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
    [self updateFiles:^(){
        [self.refreshControl endRefreshing];
        [self reloadTableData];
    }];
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
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    }
    else
    {
        self.navigationItem.title = [self.type capitalizedString];

    }
    
    [self updateFiles:^{
        [self reloadTableData];
    }];
    
}

-(void)viewDidDisappear:(BOOL)animated{
    self.fetchedResultsController = nil;
}

- (void)fetchData{
    NSError * error = [NSError new];
    if([self.fetchedResultsController performFetch:&error]){
        NSLog(@"✅ fetch success with items -> %@",self.fetchedResultsController.fetchedObjects);
        [self.tableView reloadData];
    }else{
        NSLog(@"❌ fetch error desc -> %@",error.localizedDescription);
    }
}

- (void)userWasSignedIn
{
    [self.pullToRefresh startRefresh];
    [self updateFiles:^(){
        [self.pullToRefresh finishRefresh];
        [self reloadTableData];
    }];
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
    
    [self.sessionProvider checkUserAuthorization:^(BOOL authorised, BOOL offline, BOOL isP8) {
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)pullToRefreshDidStart
{
    [self updateFiles:^(){
        [self.pullToRefresh finishRefresh];
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
         predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND name CONTAINS[cd] %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath,text];
    
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath];
    }
    
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    [self fetchData];
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



- (UIImage *)snapshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [[UIScreen mainScreen] scale]);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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
//            [self.navigationController presentViewController:gallery animated:YES completion:nil];
        }
        else if([[object isLink] boolValue]){
            if([object.linkUrl rangeOfString:@"youtube"].location == NSNotFound){
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:object.linkUrl]];
            }else{
                NSArray *arr = [object.linkUrl componentsSeparatedByString:@"//"];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@",youTubeSheme,[arr lastObject]]];
                if ([[UIApplication sharedApplication]canOpenURL:url]) {
                     [[UIApplication sharedApplication]openURL:url];
                }else{
                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:object.linkUrl]];
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
    cell.delegate = self;
    [cell setupCellForFile:object];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self removeFileFromCloud:indexPath];
    }
}

- (IBAction)signOut:(id)sender
{
    [self signOut];
}

-(void)signOut{
    [self.sessionProvider logout:^(BOOL succsess, NSError *error) {
        if (succsess) {
            SignInViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
            signIn.delegate = self;
            [self presentViewController:signIn animated:YES completion:^(){}];
        }
    }];
}


-(void)showDownloadedFiles{
    [self performSegueWithIdentifier:@"ShowDownloadsSegue" sender:nil];
}

- (void)updateFiles:(void (^)())handler
{
    if ([Settings domain]) {
        [self.storageManager updateFilesWithType:self.type forFolder:self.folder withCompletion:^(){
            if (handler)
            {
                handler();
                [self fetchData];
                id <NSFetchedResultsSectionInfo> info = self.fetchedResultsController.sections[0];
                if ([info numberOfObjects]==0) {
                    noDataLabel.text = @"Folder is empty";
                }
            }
        }];
    }
}

- (void)reloadTableData
{
    [self.tableView reloadData];
}

#pragma mark FilesTableViewCellDelegate

- (void)tableViewCellDownloadAction:(UITableViewCell *)cell
{
    if (![Settings isFirstRun]) {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Download files", @"") message:NSLocalizedString(@"Tapping this icon makes the file available offline. The file will be stored on your device locally. If you want to remove the file from the device, just tap the icon again making it grey and the file won't consume space on your device anymore.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Got it!", @"") otherButtonTitles:nil, nil];
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
    if (self.isP8) {
        [[ApiP8 filesModule]getFileView:folder type:self.type withProgress:^(float progress) {
            
        } withCompletion:^(NSString *thumbnail) {
            folder.content = thumbnail;
            if ([folder.thumb boolValue]) {
                NSString *parentPath = folder.parentPath ? folder.parentPath : @"";
                [[ApiP8 filesModule]getThumbnailForFileNamed:folder.name type:self.type path:parentPath withCompletion:^(NSString *thumbnail) {
                    folder.thumbnailLink = thumbnail;
                    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.afterlogic.files"];
                    NSURLSession * session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
                    NSLog(@"%@",[NSURL URLWithString:[folder downloadLink]]);
                    NSURLSessionDownloadTask * downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:[folder downloadLink]]];
                    folder.downloadIdentifier = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
                    NSError * error;
                    [folder.managedObjectContext save:&error];
                    [downloadTask resume];
                }];
            }
            
        }];
    }else{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.afterlogic.files"];
        NSURLSession * session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
        NSLog(@"%@",[NSURL URLWithString:[folder downloadLink]]);
        NSURLSessionDownloadTask * downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:[folder downloadLink]]];
        folder.downloadIdentifier = [NSNumber numberWithUnsignedInteger:downloadTask.taskIdentifier];
        NSError * error;
        [folder.managedObjectContext save:&error];
        self.downloadedItem = folder;
        [downloadTask resume];
    }
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
            Folder * file = [[self.defaultMOC  executeFetchRequest:fetchDownloadRequest error:&error] firstObject];
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
        NSLog(@"%@",error);
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
    Folder * file = [[self.defaultMOC  executeFetchRequest:fetchDownloadRequest error:&error] firstObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *destinationFilename = file.name;
    
    NSURL *destinationURL = [[self downloadURL] URLByAppendingPathComponent:destinationFilename];
    destinationURL = [NSURL fileURLWithPath:[destinationURL absoluteString]];
    NSLog(@"%@",[self downloadURL]);
    NSLog(@"%@",destinationURL);
    
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
            NSLog(@"failed to download %@", [error userInfo]);
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
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    
    [alert addAction:[self renameCurrentFolderAction]];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    NSLog(@"%s",__PRETTY_FUNCTION__);
}

#pragma mark - Help Methods
-(void)removeFileFromDevice:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * path = [[[object downloadURL] URLByAppendingPathComponent:object.name] absoluteString];
    
    NSFileManager * manager = [NSFileManager defaultManager];
    NSError * error;
    [manager removeItemAtURL:[NSURL fileURLWithPath:path] error:&error];
    if (self.isP8){
        [self.storageManager removeSavedFilesForItem:object];
    }
    object.isDownloaded = @NO;
    
    if (error)
    {
        NSLog(@"%@",[error userInfo]);
    }
    
    [self.defaultMOC  save:nil];
    
}

-(void)removeFileFromCloud:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    object.wasDeleted = @YES;
    if ([[Settings version] isEqualToString:@"P8"]) {
        [[ApiP8 filesModule]deleteFile:object isCorporate:self.isCorporate completion:^(BOOL succsess) {
            if (succsess) {
                [self.defaultMOC  save:nil];
            }
        }];
    }else{
        [[ApiP7 sharedInstance] deleteFile:object isCorporate:self.isCorporate completion:^(NSDictionary* handler){
            NSLog(@"%@",handler);
            [self.defaultMOC  save:nil];
        }];
    }
}


#pragma mark NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController{
    
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSSortDescriptor *isFolder = [[NSSortDescriptor alloc] initWithKey:@"isFolder" ascending:NO];
    NSSortDescriptor *title = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND wasDeleted= NO AND isP8 = %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath ? self.folder.fullpath : @"", [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
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
                NSLog(@"insert fold name is -> %@",fold.name);
                break;
            case 2:
                NSLog(@"deleted fold name is -> %@",fold.name);
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



#pragma mark Edit Menu Actions

- (IBAction)uploadAction:(id)sender {
    [self.pickerController show];
}

- (IBAction)editAction:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    self.folderToOperate = _folder;
    [alert addAction:[self createFolderAction]];
    
    if (self.folder)
    {
        [alert addAction:[self renameCurrentFolderAction]];
    }
    [alert addAction:[self savedFiles]];
    [alert addAction:[self logout]];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction*)savedFiles{
    UIAlertAction* logout = [UIAlertAction actionWithTitle:NSLocalizedString(@"Downloads", @"") style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self showDownloadedFiles];
                                                   }];
    return logout;
}

- (UIAlertAction*)logout
{
    UIAlertAction* logout = [UIAlertAction actionWithTitle:NSLocalizedString(@"Logout", @"") style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           [self signOut];
                                                       }];
    return logout;
}



- (void)CRMediaPickerController:(CRMediaPickerController *)mediaPickerController didFinishPickingAsset:(ALAsset *)asset error:(NSError *)error{
    NSLog(@"current asset - > %@ ",asset.defaultRepresentation.url);
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    Byte *buffer = (Byte*)malloc((NSUInteger)rep.size);
    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(NSUInteger)rep.size error:nil];
    NSData *fileData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
    NSString *realFileName = asset.defaultRepresentation.filename;
    NSLog(@"current fileData - > %@ ",fileData);
    NSString* MIMEType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass
    ((__bridge CFStringRef)[rep UTI], kUTTagClassMIMEType);

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.label.text = [NSString stringWithFormat:@"%@ uploading", realFileName];
    
    if ([[Settings version]isEqualToString:@"P8"]) {
        [[ApiP8 filesModule] uploadFile:fileData mime:MIMEType toFolderPath:self.folder.fullpath withName:realFileName isCorporate:self.isCorporate uploadProgressBlock:^(float progress) {
             hud.progress = progress;
        } completion:^(BOOL result) {
            if (result) {
                [self updateFiles:^(){
                    [hud hideAnimated:YES];
                    [self reloadTableData];
                }];
            }else{
                [hud hideAnimated:YES];
            }

        }];
    }else{
        NSString * path = self.isCorporate ? @"corporate" : @"personal";
        if (self.folder.fullpath)
        {
            path = [NSString stringWithFormat:@"%@%@",path,self.folder.fullpath];
        }
        [[ApiP7 sharedInstance] putFile:fileData toFolderPath:path withName:realFileName uploadProgressBlock:^(float progress) {
            hud.progress = progress;
        } completion:^(NSDictionary * response){
            NSLog(@"%@",response);
            [self updateFiles:^(){
                [hud hideAnimated:YES];
            }];
        }];
    }
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
//        NSLog(@"%@",response);
//        [self updateFiles:^(){
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//        }];
//    }];
}

- (UIAlertAction*)deleteFolderAction
{
    UIAlertAction * deleteFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action){
        Folder * object = self.folderToOperate;
//        object.wasDeleted = @YES;
        [self.storageManager deleteItem:object];
        if ([[Settings version] isEqualToString:@"P8"]) {
            [[ApiP8 filesModule]deleteFile:object isCorporate:self.isCorporate completion:^(BOOL succsess) {
                if (succsess) {
                    [self updateFiles:^(){
                        [self.tableView reloadData];
                    }];
                }
            }];
        }else{
            [[ApiP7 sharedInstance] deleteFile:object isCorporate:self.isCorporate completion:^(NSDictionary* handler){
                [self updateFiles:^(){
                    [self.tableView reloadData];
                }];
            }];
        }
    }];
    
    return deleteFolder;
}

- (UIAlertAction*)renameCurrentFolderAction
{
    NSString * text = [self.folderToOperate isEqual:self.folder] ? NSLocalizedString(@"Rename Current Folder", @"") : NSLocalizedString(@"Rename", @"");
    UIAlertAction* renameFolder = [UIAlertAction actionWithTitle:text style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIAlertController * createFolder = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                             [createFolder addTextFieldWithConfigurationHandler:^(UITextField * textField){
                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 textField.text = _folderToOperate.name;
                                                                 self.folderName = textField;
                                                             }];
                                                             
                                                             UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                 if (!_folderToOperate)
                                                                 {
                                                                     return ;
                                                                 }
                                                                 _fetchedResultsController.delegate = nil;
                                                                 _fetchedResultsController = nil;
                                                                 
                                                                 [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                                 
                                                                 [self.storageManager  renameFolder:_folderToOperate toNewName:self.folderName.text withCompletion:^(Folder * folder) {
                                                                     if (folder && !folder.isFault) {
                                                                         self.folderToOperate = folder;
                                                                         self.folder = folder;
                                                                         self.title = folder.name;
                                                                         NSError * error = nil;
                                                                         [self fetchData];
                                                                         if (error)
                                                                         {
                                                                             NSLog(@"%@",[error userInfo]);
                                                                         }

                                                                     }
                                                                    [self updateFiles:^(){
                                                                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                         [self.tableView reloadData];
                                                                     }];
                                                                    
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

- (UIAlertAction*)createFolderAction
{
    
    UIAlertAction* createFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create Folder", @"") style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIAlertController * createFolder = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Name", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                             [createFolder addTextFieldWithConfigurationHandler:^(UITextField * textField){
                                                                 textField.placeholder = NSLocalizedString(@"Folder Name", @"");
                                                                 
                                                                 self.folderName = textField;
                                                             }];
                                                             
                                                             UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                 
                                                                 [self.storageManager createFolderWithName:self.folderName.text isCorporate:self.isCorporate andPath:self.folder.fullpath completion:^(BOOL success) {
                                                                     if (success) {
                                                                         [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                                         [self updateFiles:^(){
                                                                             [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                             [self.tableView reloadData];
                                                                         }];
                                                                     }
                                                                 }];
                                                                 
                                                            }];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                                                                 
                                                             }];
                                                             [createFolder addAction:defaultAction];
                                                             [createFolder addAction:cancelAction];
                                                             [self presentViewController:createFolder animated:YES completion:nil];
                                                         }];
    return createFolder;
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
            vc.isP8 = YES;
        }else{
            viewLink = [NSString stringWithFormat:@"%@/?/Raw/FilesView/%@/%@/0/hash/%@",[Settings domain],[Settings currentAccount],[object folderHash],[Settings authToken]];
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
}



@end

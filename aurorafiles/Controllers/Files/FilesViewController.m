//
//  FilesViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "FilesViewController.h"
#import "FilesTableViewCell.h"
#import "FileDetailViewController.h"
#import "SessionProvider.h"
#import "FileGalleryCollectionViewController.h"
#import "Settings.h"
#import "API.h"
#import "SignInViewController.h"
#import "UIImage+Aurora.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "STZPullToRefresh.h"
#import "StorageManager.h"
#import <MBProgressHUD.h>

@interface FilesViewController () <UITableViewDataSource, UITableViewDelegate,SignControllerDelegate,STZPullToRefreshDelegate,NSFetchedResultsControllerDelegate,UISearchBarDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, FilesTableViewCellDelegate,NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession * session;
@property (strong, nonatomic) NSString * type;
@property (strong, nonatomic) IBOutlet UIView *activityView;
@property (strong, nonatomic) STZPullToRefresh * pullToRefresh;
@property (strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) UITextField * folderName;
@property (strong, nonatomic) Folder * folderToOperate;

@end

@implementation FilesViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.isCorporate = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.managedObjectContext = [[StorageManager sharedManager] managedObjectContext];
    STZPullToRefreshView *refreshView = [[STZPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1.5)];
    [self.view addSubview:refreshView];
    
//
//    // Setup PullToRefresh
    self.pullToRefresh = [[STZPullToRefresh alloc] initWithTableView:nil
                                                         refreshView:refreshView
                                                   tableViewDelegate:nil];
//
    self.isCorporate = [self.type isEqualToString:@"corporate"];
    [[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL * url){
        
        return [url absoluteString];
    }];
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.signOutButton.tintColor = refreshView.progressColor;
    self.editButton.tintColor = refreshView.progressColor;
    [self.refreshControl addTarget:self action:@selector(tableViewPullToRefresh:) forControlEvents:UIControlEventValueChanged];
    self.searchBar.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[FilesTableViewCell cellId]];
    [self.pullToRefresh startRefresh];
    [self updateFiles:^() {
        [self.pullToRefresh finishRefresh];
    }];
    // Do any additional setup after loading the view.
}

- (void)setFolder:(Folder *)folder
{
    _folder = folder;
    if (folder)
    {
        self.title = folder.name;
    }
}

- (void)tableViewPullToRefresh:(UIRefreshControl*)sender
{
    [self updateFiles:^(){
        [self.refreshControl endRefreshing];
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
        self.navigationItem.rightBarButtonItems = @[self.editButton];

    }
    else
    {
        self.navigationItem.title = [self.type capitalizedString];
        self.navigationItem.leftBarButtonItems = @[self.signOutButton];
        self.navigationItem.rightBarButtonItems = @[self.editButton];

    }
    NSError * error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    [self updateFiles:^(){
    
    }];
}

- (void)userWasSignedIn
{
    [self.pullToRefresh startRefresh];
    [self updateFiles:^(){
        [self.pullToRefresh finishRefresh];
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
        NSLog(@"vc class is -> %@",[vc class] );
        [vc setEnabled:NO];
    };
//    NSLog(@"buttons locked" );
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [SessionProvider checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline){
        if(authorised && offline){
            [self userWasSigneInOffline];
            return;
        }
        if (!authorised)
        {
            SignInViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
            signIn.delegate = self;
            [self presentViewController:signIn animated:YES completion:^(){
            
            }];
        }
    }];
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


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GoToFolderSegue"])
    {
        Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        FilesViewController * vc = [segue destinationViewController];
        vc.folder = object;
        vc.isCorporate = self.isCorporate;
    }
    if ([segue.identifier isEqualToString:@"OpenFileSegue"])
    {
        Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        
        NSString * viewLink = [NSString stringWithFormat:@"https://%@/?/Raw/FilesView/%@/%@/0/hash/%@",[Settings domain],[Settings currentAccount],[object folderHash],[Settings authToken]];
        FileDetailViewController * vc = [segue destinationViewController];
        if (object.isDownloaded.boolValue)
        {
            viewLink = [[[self downloadURL] URLByAppendingPathComponent:object.name] absoluteString];
        }
        vc.viewLink = viewLink;
        vc.object = object;

    }
    if ([segue.identifier isEqualToString:@"OpenFileGallerySegue"])
    {
        Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        FileGalleryCollectionViewController * vc = [segue destinationViewController];
        vc.folder = self.folder;
        UIImage * snap = [self snapshot:self.navigationController.view];
        vc.snapshot= snap;
        
        vc.currentItem = object;
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

#pragma mark TableView

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
    if ([object.isFolder boolValue])
    {
        [self performSegueWithIdentifier:@"GoToFolderSegue" sender:self];
    }
    else
    {
        if ([object isImageContentType] && ![[object isLink] boolValue])
        {
            [self performSegueWithIdentifier:@"OpenFileGallerySegue" sender:self];
        }
        else
        {
            [self performSegueWithIdentifier:@"OpenFileSegue" sender:self];
        }
        
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
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (!object.canEdit)
        return NO;
    return YES;
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
    cell.delegate = self;
    if ([[object isFolder] boolValue])
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.disclosureButton.alpha = 0.0f;
        cell.fileImageView.image = [UIImage imageNamed:@"folder"];
    }
    else
    {
        
        cell.fileImageView.image = nil;
        UIImage * placeholder = [UIImage assetImageForContentType:[object validContentType]];
        if (object.isLink.boolValue && ![object isImageContentType])
        {
            placeholder = [UIImage imageNamed:@"shotcut"];
        }
        if (object.downloadIdentifier.integerValue != -1)
        {
            [cell.downloadActivity startAnimating];
            cell.disclosureButton.hidden = YES;
        }
        else
        {
            [cell.downloadActivity stopAnimating];
            cell.disclosureButton.hidden = NO;
        }
//        [cell.disclosureButton setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
//        [cell.disclosureButton setImage:[UIImage imageNamed:@"onboard"] forState:UIControlStateDisabled];
//        cell.disclosureButton.enabled = !object.isDownloaded.boolValue;
        
        [cell.disclosureButton setImage: !object.isDownloaded.boolValue ? [UIImage imageNamed:@"download"] :[UIImage imageNamed:@"removeFromDevice"] forState:UIControlStateNormal];
        cell.fileDownloaded = object.isDownloaded.boolValue;
        
        cell.fileImageView.image =placeholder;
        cell.disclosureButton.alpha = 1.0f;
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSString * thumbnail = [object embedThumbnailLink];
        
        if (thumbnail)
        {
            [cell.fileImageView sd_setImageWithURL:[NSURL URLWithString:thumbnail] placeholderImage:placeholder options:SDWebImageRefreshCached];
        }
    }


    cell.titileLabel.text = object.name;
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
    [Settings setAuthToken:nil];
    [Settings setCurrentAccount:nil];
    [Settings setToken:nil];
    [Settings setPassword:nil];

    [SessionProvider checkAuthorizeWithCompletion:^(BOOL authorised, BOOL offline){
        if (!authorised)
        {
            
            SignInViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
            signIn.delegate = self;
            [self presentViewController:signIn animated:YES completion:^(){
                
            }];
        }
    }];
}

- (void)updateFiles:(void (^)())handler
{
    [self reloadTableData];
    
    [[StorageManager sharedManager] updateFilesWithType:self.isCorporate ? @"corporate" : @"personal" forFolder:self.folder withCompletion:^(){
        if (handler)
        {
            handler();
        }
    }];
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
    NSLog(@"%@",[NSURL URLWithString:[folder downloadLink]]);
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
    Folder * file = [[self.managedObjectContext executeFetchRequest:fetchDownloadRequest error:&error] firstObject];
    
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
    object.isDownloaded = @NO;
    
    if (error)
    {
        NSLog(@"%@",[error userInfo]);
    }
    
    [self.managedObjectContext save:nil];
    
}

-(void)removeFileFromCloud:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    object.wasDeleted = @YES;
    [[API sharedInstance] deleteFile:object isCorporate:self.isCorporate completion:^(NSDictionary* handler){
        NSLog(@"%@",handler);
        [self.managedObjectContext save:nil];
    }];

}


#pragma mark NSFetchedResultsController

- (NSFetchedResultsController*)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Folder" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *isFolder = [[NSSortDescriptor alloc]
                              initWithKey:@"isFolder" ascending:NO];
    NSSortDescriptor *title = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:@[isFolder, title]];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND wasDeleted= NO",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    NSError * error;
    [_fetchedResultsController performFetch:&error];
    return _fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}
#pragma mark More Actions



#pragma mark Edit Menu Actions

- (IBAction)editAction:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    self.folderToOperate = self.folder;
    [alert addAction:[self createFolderAction]];
    [alert addAction:[self uploadFileAction]];
    
    if (self.folder)
    {
        [alert addAction:[self renameCurrentFolderAction]];
    }
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIAlertAction*)uploadFileAction
{
    UIAlertAction* uploadFile = [UIAlertAction actionWithTitle:NSLocalizedString(@"Upload File", @"") style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                                           picker.delegate = self;
                                                           picker.allowsEditing = YES;
                                                           picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
                                                           
                                                           [self presentViewController:picker animated:YES completion:NULL];
                                                       }];
    
    return uploadFile;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    NSURL *urlFile = [info objectForKey:UIImagePickerControllerReferenceURL];
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],[[urlFile path] lastPathComponent]];
    
    NSData * data = UIImagePNGRepresentation(image);
    NSString * path = self.isCorporate ? @"corporate" : @"personal";
    if (self.folder.fullpath)
    {
        path = [NSString stringWithFormat:@"%@%@",path,self.folder.fullpath];
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[API sharedInstance] putFile:data toFolderPath:path withName:fileName completion:^(NSDictionary * response){
        NSLog(@"%@",response);
        [self updateFiles:^(){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
    }];
}

- (UIAlertAction*)deleteFolderAction
{
    UIAlertAction * deleteFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action){
        Folder * object = self.folderToOperate;
        object.wasDeleted = @YES;
        [self.managedObjectContext save:nil];

        [[API sharedInstance] deleteFile:object isCorporate:self.isCorporate completion:^(NSDictionary* handler){
            [self updateFiles:^(){
                
                [self.tableView reloadData];
            }];
        }];
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
                                                                 textField.text = self.folderToOperate.name;
                                                                 self.folderName = textField;
                                                             }];
                                                             
                                                             UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                 if (!self.folderToOperate)
                                                                 {
                                                                     return ;
                                                                 }
                                                                 _fetchedResultsController.delegate = nil;
                                                                 _fetchedResultsController = nil;
                                                                 
                                                                 [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                                 [[StorageManager sharedManager] renameFolder:self.folderToOperate toNewName:self.folderName.text withCompletion:^(Folder * folder) {
                                                                     self.folderToOperate = folder;
                                                                     self.folder = folder;
                                                                     self.title = folder.name;
                                                                     NSError * error = nil;
                                                                     [self.fetchedResultsController performFetch:&error];
                                                                     if (error)
                                                                     {
                                                                         NSLog(@"%@",[error userInfo]);
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
                                                                 [[API sharedInstance] createFolderWithName:self.folderName.text isCorporate:self.isCorporate andPath:self.folder.fullpath ? self.folder.fullpath : @"" completion:^(NSDictionary * result){
                                                                     NSLog(@"%@",result);
                                                                     [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                                     [self updateFiles:^(){
                                                                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                         
                                                                         [self.tableView reloadData];
                                                                     }];
                                                                 }];;
                                                                 
                                                             }];
                                                             
                                                             UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                                                                 
                                                             }];
                                                             [createFolder addAction:defaultAction];
                                                             [createFolder addAction:cancelAction];
                                                             [self presentViewController:createFolder animated:YES completion:nil];
                                                         }];
    return createFolder;
}


@end

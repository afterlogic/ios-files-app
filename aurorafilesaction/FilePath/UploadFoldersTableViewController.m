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

@interface UploadFoldersTableViewController () <UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate,UISearchBarDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, FilesTableViewCellDelegate,NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession * session;
@property (strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) UITextField * folderName;
@property (strong, nonatomic) Folder * folderToOperate;
@property (strong, nonatomic) Folder * folderToNavigate;
@property (weak, nonatomic) IBOutlet UIRefreshControl *refreshController;


@end

@implementation UploadFoldersTableViewController

- (void)loadView{
    NSLog(@"self -> %@",self);
    [super loadView];
    NSLog(@"self after super load -> %@",self);
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
    
    [self.refreshController addTarget:self action:@selector(tableViewPullToRefresh:) forControlEvents:UIControlEventValueChanged];
    self.searchBar.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[FilesTableViewCell cellId]];
    [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 50, self.tableView.contentInset.right)];
    [self updateFiles:^{
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
            vc.EditButton = self.EditButton;
        };
        NSLog(@"curentControllersStack %@",curentControllersStack);
        for (UploadFoldersTableViewController* vc in controllersStack) {
                [self.navigationController pushViewController:vc animated:NO];
        }
        
    }
}

- (void)tableViewPullToRefresh:(UIRefreshControl*)sender
{
    [self updateFiles:^(){
        [self.refreshController endRefreshing];
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
        self.navigationItem.leftBarButtonItem = self.backButton;
        self.navigationItem.rightBarButtonItems = @[self.doneButton, self.EditButton];
        
        [self.delegate currentFolder:self.folder root:self.type];
        
    }
    else
    {
        self.navigationItem.title = [self.type capitalizedString];
        self.navigationItem.rightBarButtonItems = @[self.doneButton,self.EditButton];
        
    }
    NSError * error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    [self updateFiles:^(){
        
    }];
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
    
    [[SessionProvider sharedManager] checkUserAuthorization:^(BOOL authorised, BOOL offline,BOOL isP8){
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
    cell.delegate = self;
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
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    BFLog(@"%s",__PRETTY_FUNCTION__);
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
        BFLog(@"%@",[error userInfo]);
    }
    
    [self.managedObjectContext save:nil];
    
}

-(void)removeFileFromCloud:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    object.wasDeleted = @YES;
    if ([[Settings version] isEqualToString:@"P8"]) {
//        [[ApiP8 filesModule]deleteFile:object isCorporate:self.isCorporate completion:^(BOOL succsess) {
//            if (succsess) {
//            BFLog(@"%@",handler);
//            [self.managedObjectContext save:nil];
//            }
//        }];
    }else{
        [[ApiP7 sharedInstance] deleteFile:object isCorporate:self.isCorporate completion:^(NSDictionary* handler){
            BFLog(@"%@",handler);
            [self.managedObjectContext save:nil];
        }];
    }
}


#pragma mark NSFetchedResultsController

- (NSFetchedResultsController*)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription
//                                   entityForName:@"Folder" inManagedObjectContext:self.managedObjectContext];
//    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *isFolder = [[NSSortDescriptor alloc]
                                  initWithKey:@"isFolder" ascending:NO];
    NSSortDescriptor *title = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
//    [fetchRequest setSortDescriptors:@[isFolder, title]];
    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND wasDeleted= NO",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@ AND parentPath = %@ AND wasDeleted= NO AND isP8 = %@",self.folder ? self.folder.type : (self.isCorporate ? @"corporate": @"personal"), self.folder.fullpath ? self.folder.fullpath : @"", [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
//    [fetchRequest setReturnsObjectsAsFaults:NO];
    
//    NSFetchedResultsController *theFetchedResultsController =
//    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
//                                        managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil
//                                                   cacheName:nil];
//    self.fetchedResultsController = theFetchedResultsController;
//    _fetchedResultsController.delegate = self;
    NSError * error;

    
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *req = [Folder getFetchRequestInContext:moc descriptors:@[isFolder, title] predicate:predicate];
    
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
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose option", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                          }];
    
    self.folderToOperate = self.folder;
    [alert addAction:[self createFolderAction]];
    if (self.folder)
    {
        [alert addAction:[self renameCurrentFolderAction]];
    }
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

//- (UIAlertAction*)uploadFileAction
//{
//    UIAlertAction* uploadFile = [UIAlertAction actionWithTitle:NSLocalizedString(@"Upload File", @"") style:UIAlertActionStyleDefault
//                                                       handler:^(UIAlertAction * action) {
//                                                           UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//                                                           picker.delegate = self;
//                                                           picker.allowsEditing = YES;
//                                                           picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//                                                           picker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil ];
//                                                           
//                                                           [self presentViewController:picker animated:YES completion:NULL];
//                                                       }];
//    
//    return uploadFile;
//}
//
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
//{
//    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
//    
//    NSURL *urlFile = [info objectForKey:UIImagePickerControllerReferenceURL];
//    [picker dismissViewControllerAnimated:YES completion:nil];
//    NSString *fileName = [NSString stringWithFormat:@"%@_%@",[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]],[[urlFile path] lastPathComponent]];
//    
//    NSData * data = UIImagePNGRepresentation(image);
//    NSString * path = self.isCorporate ? @"corporate" : @"personal";
//    if (self.folder.fullpath)
//    {
//        path = [NSString stringWithFormat:@"%@%@",path,self.folder.fullpath];
//    }
////    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    [[ApiP7 sharedInstance] putFile:data toFolderPath:path withName:fileName completion:^(NSDictionary * response){
//        BFLog(@"%@",response);
//        [self updateFiles:^(){
////            [MBProgressHUD hideHUDForView:self.view animated:YES];
//        }];
//    }];
//}

- (UIAlertAction*)deleteFolderAction
{
    UIAlertAction * deleteFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action){
        Folder * object = self.folderToOperate;
        object.wasDeleted = @YES;
        [self.managedObjectContext save:nil];
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

                                                                 [[StorageManager sharedManager] renameFolder:self.folderToOperate toNewName:self.folderName.text withCompletion:^(Folder * folder) {
                                                                     self.folderToOperate = folder;
                                                                     self.folder = folder;
                                                                     self.title = folder.name;
                                                                     NSError * error = nil;
                                                                     [self.fetchedResultsController performFetch:&error];
                                                                     if (error)
                                                                     {
                                                                         BFLog(@"%@",[error userInfo]);
                                                                     }
                                                                     [self updateFiles:^(){
//                                                                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                                         
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
                                                                 __weak typeof (self)weakSelf = self;
                                                                 [[StorageManager sharedManager]createFolderWithName:self.folderName.text isCorporate:self.isCorporate andPath:self.folder.fullpath completion:^(BOOL success) {
                                                                     if (success) {
                                                                         [self updateFiles:^(){
                                                                             [self.tableView reloadData];
                                                                             __strong typeof(self)self = weakSelf;
                                                                             NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@ AND isFolder == YES", weakSelf.folderName.text];
                                                                             NSArray *filteredArray = [[self.fetchedResultsController fetchedObjects]filteredArrayUsingPredicate:predicate];
                                                                             NSLog(@"%@", filteredArray);
                                                                             self.folderToNavigate = [filteredArray lastObject];
                                                                             [self performSegueWithIdentifier:@"GoToFolderSegue" sender:self];
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
@end

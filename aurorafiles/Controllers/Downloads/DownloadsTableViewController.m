//
//  DownloadsTableViewController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 28/06/16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "DownloadsTableViewController.h"
#import <CoreData/CoreData.h>
#import "FilesTableViewCell.h"
#import "StorageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Aurora.h"
#import "FileDetailViewController.h"
#import "FileGalleryCollectionViewController.h"
#import "GalleryWrapperViewController.h"
#import "Settings.h"
#import "SessionProvider.h"

@interface DownloadsTableViewController () <NSFetchedResultsControllerDelegate,FilesTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolBar;
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@end

@implementation DownloadsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.managedObjectContext = [[[StorageManager sharedManager] DBProvider]defaultMOC];
    [self.tableView registerNib:[UINib nibWithNibName:@"FilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[FilesTableViewCell cellId]];
    
    self.searchBar.delegate = self;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated{

    [self.toolBar setHidden:YES];
    if ([self.loadType isEqualToString:loadTypeView]) {
        [self.navigationController.navigationBar setHidden:NO];
        [self.navigationController setTitle:NSLocalizedString(@"Downloads", @"")];
    }else{
        [self.navigationController.navigationBar setHidden:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    
}

- (void)viewWillDisappear:(BOOL)animated{
//    self.loadType = loadTypeContainer;
    
}

- (void)stopTasks{
//    [[SessionProvider sharedManager] cancelAllOperations];
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
        predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ AND isP8 = %@ AND isDownloaded = YES",text, [NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
    }
    else
    {
        predicate = [NSPredicate predicateWithFormat:@"isDownloaded = YES AND isP8 = %@",[NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
    }
    
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    [self.fetchedResultsController performFetch:nil];
    NSArray * newItems = self.fetchedResultsController.fetchedObjects;
    
    NSMutableArray * indexPathsToInsert = [[NSMutableArray alloc] init];
    
    indexPathsToInsert = [[NSMutableArray alloc] init];
    for (id obj in newItems)
    {
        [indexPathsToInsert addObject:[self.fetchedResultsController indexPathForObject:obj]];
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationNone];
    //    if (indexPathsToInsert.count > 0) {
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationNone];
    //    }
    [self.tableView endUpdates];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> info = [self.fetchedResultsController sections][section];
    return [info numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    FilesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[FilesTableViewCell cellId] forIndexPath:indexPath];
    cell.delegate = self;
    cell.imageView.image = nil;
    
        
    
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
        [cell.disclosureButton setImage: !object.isDownloaded.boolValue ? [UIImage imageNamed:@"download"] :[UIImage imageNamed:@"onboard"] forState:UIControlStateNormal];
    
        cell.fileDownloaded = object.isDownloaded.boolValue;
    
        cell.fileImageView.image = placeholder;
        cell.disclosureButton.alpha = 1.0f;
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSString * thumbnail = [object embedThumbnailLink];
        
        if (thumbnail)
        {
            [cell.fileImageView sd_setImageWithURL:[NSURL URLWithString:thumbnail] placeholderImage:placeholder options:SDWebImageRefreshCached];
        }
    
    cell.titileLabel.text = object.name;
    return cell;

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self removeFileFromDevice:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
    if ([object isImageContentType] && ![[object isLink] boolValue])
    {
        [self performSegueWithIdentifier:@"OpenDownloadFileGallerySegue" sender:self];
    }
    else if([[object isLink] boolValue]){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:object.linkUrl]];
    }
    else{
        [self performSegueWithIdentifier:@"OpenFileSegue" sender:self];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


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
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isDownloaded = YES AND isP8 = %@",[NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]]];
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [FilesTableViewCell cellHeight];
}

#pragma mark - Cell Delegate

-(void)tableViewCellDownloadAction:(UITableViewCell *)cell{
    
}

-(void)tableViewCellRemoveAction:(UITableViewCell *)cell{
    [self removeFileFromDevice:[self.tableView indexPathForCell:cell]];
}


#pragma mark - Help Methods

-(void)removeFileFromDevice:(NSIndexPath *)indexPath{
    Folder * object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString * path = [[[Folder downloadsDirectoryURL] URLByAppendingPathComponent:object.name] absoluteString];
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

- (UIImage *)snapshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [[UIScreen mainScreen] scale]);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenFileSegue"])
    {
        Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        NSString * viewLink;
        FileDetailViewController * vc = [segue destinationViewController];
        if (object.isDownloaded.boolValue)
        {
            viewLink = [object localURL].absoluteString;
        }
        vc.viewLink = viewLink;
        vc.object = object;
    }

    if ([segue.identifier isEqualToString:@"OpenDownloadFileGallerySegue"])
    {
        Folder * object = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        NSFetchRequest * fetchImageFilesItemsRequest = [NSFetchRequest fetchRequestWithEntityName:@"Folder"];
        fetchImageFilesItemsRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        fetchImageFilesItemsRequest.predicate = [NSPredicate predicateWithFormat:@"isDownloaded = YES AND isP8 = %@ AND isFolder == NO AND contentType IN (%@)",[NSNumber numberWithBool:[[Settings version] isEqualToString:@"P8"]],[Folder imageContentTypes]];
        NSError * error = [NSError new];
        NSArray *items = [[[[StorageManager sharedManager] DBProvider]defaultMOC] executeFetchRequest:fetchImageFilesItemsRequest error:&error];
        
        GalleryWrapperViewController * vc = [segue destinationViewController];
        vc.itemsList = items;
        vc.initialPageIndex = [items indexOfObject:object];
    }
}

@end

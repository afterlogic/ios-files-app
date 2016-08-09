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
@interface DownloadsTableViewController () <NSFetchedResultsControllerDelegate,FilesTableViewCellDelegate>
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@end

@implementation DownloadsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.managedObjectContext = [[StorageManager sharedManager] managedObjectContext];
    [self.tableView registerNib:[UINib nibWithNibName:@"FilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[FilesTableViewCell cellId]];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [cell.disclosureButton setImage: !object.isDownloaded.boolValue ? [UIImage imageNamed:@"download"] :[UIImage imageNamed:@"removeFromDevice"] forState:UIControlStateNormal];
    
//        [cell.disclosureButton setImage:[UIImage imageNamed:@"removeFromDevice"] forState:UIControlStateDisabled];
//        cell.disclosureButton.enabled = !object.isDownloaded.boolValue;
    
        cell.fileDownloaded = object.isDownloaded.boolValue;
    
        cell.fileImageView.image =placeholder;
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
    return YES;
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
    [self performSegueWithIdentifier:@"OpenFileSegue" sender:self];
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
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isDownloaded = YES"];
    
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
            viewLink = [[[object downloadURL] URLByAppendingPathComponent:object.name] absoluteString];
        }
        vc.viewLink = viewLink;
        vc.object = object;        
    }
}

@end

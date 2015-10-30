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
#import "Settings.h"
#import "API.h"
@interface FilesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) NSArray * items;
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
    [self updateFiles];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.folderPath)
    {
        self.fileTypeSegmentControl.hidden = YES;
        self.title = self.folderName;
        UILabel * titleLabel = [[UILabel alloc] init];
        titleLabel.text = self.folderName;
        [titleLabel sizeToFit];
        self.navigationItem.titleView = titleLabel;

    }
    else
    {
        self.fileTypeSegmentControl.hidden = NO;
        self.navigationItem.titleView = self.fileTypeSegmentControl;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [SessionProvider checkAuthorizeWithCompletion:^(BOOL authorized){
        if (!authorized)
        {
            UIViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
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


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GoToFolderSegue"])
    {
        NSDictionary * object = [self.items objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        FilesViewController * vc = [segue destinationViewController];
        vc.folderPath = [object objectForKey:@"FullPath"];
        vc.folderName = [object objectForKey:@"Name"];
        vc.isCorporate = self.isCorporate;
    }
    if ([segue.identifier isEqualToString:@"OpenFileSegue"])
    {
        NSDictionary * object = [self.items objectAtIndex:self.tableView.indexPathForSelectedRow.row];
        NSString * viewLink = [NSString stringWithFormat:@"https://%@/?/Raw/FilesView/%@/%@/0/hash/%@",[Settings domain],[Settings currentAccount],[object objectForKey:@"Hash"],[Settings authToken]];
        FileDetailViewController * vc = [segue destinationViewController];
        vc.viewLink = viewLink;

    }
}

#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * object = [self.items objectAtIndex:indexPath.row];
    if ([[object objectForKey:@"IsFolder"] boolValue])
        return NO;
    return YES;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * object = [self.items objectAtIndex:indexPath.row];
    UITableViewCell *cell;
    if ([[object objectForKey:@"IsFolder"] boolValue])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"FoldersTableViewCellId" forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"FilesTableViewCellId" forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell layoutIfNeeded];

    cell.textLabel.text = [object objectForKey:@"Name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        NSDictionary * object = [self.items objectAtIndex:indexPath.row];
        NSMutableArray * objects = [self.items mutableCopy];
        [objects removeObject:object];
        self.items = objects;
        [self.tableView reloadData];
        NSLog(@"%s %@",__PRETTY_FUNCTION__,object);
        [[API sharedInstance] deleteFiles:object isCorporate:self.isCorporate completion:^(NSDictionary* handler){
        NSLog(@"%s %@",__PRETTY_FUNCTION__,handler);
        }];
    }
}

- (IBAction)valueChangedSegment:(id)sender
{


    if (self.fileTypeSegmentControl.selectedSegmentIndex == 1)
    {
        self.isCorporate = YES;
    }
    else
    {
        self.isCorporate = NO;
    }
    [self updateFiles];
}

- (IBAction)signOut:(id)sender
{
    [Settings setAuthToken:nil];
    [Settings setCurrentAccount:nil];
    [Settings setToken:nil];
    [SessionProvider checkAuthorizeWithCompletion:^(BOOL authorised){
        if (!authorised)
        {
            UIViewController * signIn = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
            [self presentViewController:signIn animated:YES completion:^(){
                
            }];
        }
    }];
}

- (void)updateFiles
{
    [SessionProvider checkAuthorizeWithCompletion:^(BOOL authorised){
        if (authorised)
        {
            self.items = @[];
            
            [self.tableView reloadData];
            
            [[API sharedInstance] getFilesForFolder:self.folderPath isCorporate:self.isCorporate completion:^(NSDictionary * result) {
                if (result && [result isKindOfClass:[NSDictionary class]])
                {
                    self.items = [[result objectForKey:@"Result"] objectForKey:@"Items"];
                }
                else
                {
                    self.items = @[];
                }
                
                //@TODO remove then use CoreData
                [self.tableView reloadData];
            }];

        }
    }];

}
@end

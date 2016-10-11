//
//  ARootViewController.m
//  aurorafiles
//
//  Created by Cheshire on 11.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "ARootViewController.h"
//#import "ConnectionProvider.h"
#import "Constants.h"

@interface ARootViewController ()
{
    
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedCotnroller;
@property (weak, nonatomic) IBOutlet UIView *containerPerson;
@property (weak, nonatomic) IBOutlet UIView *containerCorporate;
@property (weak, nonatomic) IBOutlet UIView *containerDownloads;

@end

@implementation ARootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.segmentedCotnroller addTarget:self action:@selector(onSegmentedControlTap:) forControlEvents:UIControlEventValueChanged];
    [self showOnlineButtons];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showOnlineButtons) name:CPNotificationConnectionOnline object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showOfflineButtons) name:CPNotificationConnectionLost object:nil];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onSegmentedControlTap:(UISegmentedControl *)sender{
    
    if (self.segmentedCotnroller.numberOfSegments == 1) {
        [self showDownloads];
    }else{
        if (sender.selectedSegmentIndex == 0) {
            [self showPersonal];
        }
        if (sender.selectedSegmentIndex == 1) {
            [self showCorporate];
        }
    }

}

-(void)showOnlineButtons{
    [self.segmentedCotnroller removeAllSegments];
    [self.segmentedCotnroller insertSegmentWithTitle:@"Personal" atIndex:0 animated:YES];
    [self.segmentedCotnroller insertSegmentWithTitle:@"Corporate" atIndex:1 animated:YES];
    [self.segmentedCotnroller setSelectedSegmentIndex:0];
    [self showPersonal];
}


-(void)showOfflineButtons{
    [self.segmentedCotnroller removeAllSegments];
    [self.segmentedCotnroller insertSegmentWithTitle:@"Downloads" atIndex:0 animated:YES];
    [self.segmentedCotnroller setSelectedSegmentIndex:0];
    [self showDownloads];
}

-(void)showPersonal{
    [UIView animateWithDuration:0.4f animations:^{
        self.containerPerson.alpha = 1.0f;
        self.containerCorporate.alpha = 0.0f;
        self.containerDownloads.alpha = 0.0f;
    }];
}

-(void)showCorporate{
    [UIView animateWithDuration:0.4f animations:^{
        self.containerPerson.alpha = 0.0f;
        self.containerCorporate.alpha = 1.0f;
        self.containerDownloads.alpha = 0.0f;
    }];
}

-(void)showDownloads{
    [UIView animateWithDuration:0.4f animations:^{
        self.containerPerson.alpha = 0.0f;
        self.containerCorporate.alpha = 0.0f;
        self.containerDownloads.alpha = 1.0f;
    }];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"personal_embed"]){
        self.containerPerson.alpha = 1.0f;
        self.containerCorporate.alpha = 0.0f;
        self.containerDownloads.alpha = 0.0f;
    }
    if([segue.identifier isEqualToString:@"corp_embed"]){
        
    }
    if([segue.identifier isEqualToString:@"downloads_embed"]){
        
    }
}


@end

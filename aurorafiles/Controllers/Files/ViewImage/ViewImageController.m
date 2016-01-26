//
//  ViewImageController.m
//  aurorafiles
//
//  Created by Michael Akopyants on 26/01/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "ViewImageController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewImageController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ViewImageController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.viewLink]];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

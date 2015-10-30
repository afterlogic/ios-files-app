//
//  FileDetailViewController.h
//  aurorafiles
//
//  Created by Michael Akopyants on 28/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileDetailViewController : UIViewController
@property (strong, nonatomic) NSString * viewLink;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

//
//  UIApplication+openURL.m
//  aurorafiles
//
//  Created by Cheshire on 17.05.17.
//  Copyright © 2017 afterlogic. All rights reserved.
//

#import "UIApplication+openURL.h"

static NSString * iosTenPrefix = @"10";

@implementation UIApplication (openURL)

-(void)openLink:(NSURL*)link{
    if ([[UIDevice currentDevice].systemVersion hasPrefix:iosTenPrefix]){
        [[UIApplication sharedApplication] openURL:link options:@{} completionHandler:nil];
    }else{
        [[UIApplication sharedApplication] openURL:link];
    }
}

@end

//
//  UITextFieldCustomEdges.h
//  aurorafiles
//
//  Created by Michael Akopyants on 01/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextFieldCustomEdges : UITextField

@property (nonatomic, assign) CGFloat placeholderHorizontalInset;
@property (nonatomic, assign) CGFloat placeholderVerticalInset;
@property (nonatomic, assign) CGFloat textHorizontalInset;
@property (nonatomic, assign) CGFloat textVerticalInset;

@end

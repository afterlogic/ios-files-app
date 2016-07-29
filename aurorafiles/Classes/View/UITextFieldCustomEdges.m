//
//  UITextFieldCustomEdges.m
//  aurorafiles
//
//  Created by Michael Akopyants on 01/03/16.
//  Copyright © 2016 Michael Akopyants. All rights reserved.
//

#import "UITextFieldCustomEdges.h"

@implementation UITextFieldCustomEdges

- (void)awakeFromNib
{
    self.placeholderHorizontalInset = 0.0f;
    self.placeholderVerticalInset   = 0.0f;
    self.textHorizontalInset        = 0.0f;
    self.textVerticalInset          = 0.0f;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectOffset(bounds, self.textHorizontalInset, self.textVerticalInset);
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return CGRectOffset(bounds, self.placeholderHorizontalInset, self.placeholderVerticalInset);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

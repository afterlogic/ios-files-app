//
//  NSString+transferedValues.m
//  aurorafiles
//
//  Created by Cheshire on 13.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "NSString+transferedValues.h"

@implementation NSString (transferedValues)
+ (id)transformedValue:(id)value
{
    
    double convertedValue = [value doubleValue];
    int multiplyFactor = 0;
    
    NSArray *tokens = @[@"bytes",@"KB",@"MB",@"GB",@"TB", @"PB", @"EB", @"ZB", @"YB"];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, tokens[multiplyFactor]];
}
@end

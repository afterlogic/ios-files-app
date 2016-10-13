//
//  NSObject+PerformSelectorWithCallback.m
//  FreedomCost
//
//  Created by Cheshire on 03.08.15.
//
//

#import "NSObject+PerformSelectorWithCallback.h"

@implementation NSObject (PerformSelectorWithCallback)

-(void)performSelector:(SEL)aSelector withCallback:(void (^)(void))callback
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self performSelector:aSelector];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback();
        });
    });
}
@end

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

- (void)for:(NSInteger)times timesTryBlock:(void(^)(void(^)(BOOL success,NSError* error)))block;
{
    [self for:times timesTryBlock:block callback:^(BOOL success, NSError* error) {} ];
}

- (void)for:(NSInteger)times timesTryBlock:(void(^)(void(^)(BOOL success,NSError* error)))block callback:(void(^)(BOOL success,NSError* error))callback;
{
    block(^(BOOL success,NSError* error){
        if (error != nil)
        {
            if (times > 1)
                [self for:times - 1 timesTryBlock:block callback:callback];
            else
                callback(NO,error);
            return;
        }else{
            callback(YES,nil);
        }
    });
    

}
@end

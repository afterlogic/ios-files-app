//
//  NSObject+PerformSelectorWithCallback.h
//  FreedomCost
//
//  Created by Cheshire on 03.08.15.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (PerformSelectorWithCallback)

-(void)performSelector:(SEL)aSelector withCallback:(void (^)(void))callback;

@end

//
//  GalleryCollectionFlowLayout.m
//  aurorafiles
//
//  Created by Cheshire on 14.12.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import "GalleryCollectionFlowLayout.h"

@interface GalleryCollectionFlowLayout (){
    
}
@property (nonatomic) CGSize previousSize;
@property (nonatomic, strong) NSMutableArray *indexPathsToAnimate;

@end

@implementation GalleryCollectionFlowLayout


- (void)commonInit
{

}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}


-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    CGRect oldBounds = self.collectionView.bounds;
    if (!CGSizeEqualToSize(oldBounds.size, newBounds.size)) {
        return YES;
    }
    return NO;
}

- (void)prepareLayout
{
    NSLog(@"%@ preparing layout", self);
    [super prepareLayout];
//    self.previousSize = self.collectionView.bounds.size;
}

- (void)finalizeCollectionViewUpdates
{
    NSLog(@"%@ finalize updates", self);
    [super finalizeCollectionViewUpdates];
    self.indexPathsToAnimate = nil;
}

- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds
{
    NSLog(@"%@ prepare animated bounds change", self);
    [super prepareForAnimatedBoundsChange:oldBounds];
}

- (void)finalizeAnimatedBoundsChange {
    NSLog(@"%@ finalize animated bounds change", self);
    [super finalizeAnimatedBoundsChange];
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    [super prepareForCollectionViewUpdates:updateItems];
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        switch (updateItem.updateAction) {
            case UICollectionUpdateActionInsert:
                [indexPaths addObject:updateItem.indexPathAfterUpdate];
                break;
            case UICollectionUpdateActionDelete:
                [indexPaths addObject:updateItem.indexPathBeforeUpdate];
                break;
            case UICollectionUpdateActionMove:
                [indexPaths addObject:updateItem.indexPathBeforeUpdate];
                [indexPaths addObject:updateItem.indexPathAfterUpdate];
                break;
            default:
                NSLog(@"unhandled case: %@", updateItem);
                break;
        }
    }
    self.indexPathsToAnimate = indexPaths;
}

- (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    
    if ([_indexPathsToAnimate containsObject:itemIndexPath]) {
        attr.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(0.2, 0.2), M_PI);
        attr.center = CGPointMake(CGRectGetMidX(self.collectionView.bounds), CGRectGetMaxY(self.collectionView.bounds));
        [_indexPathsToAnimate removeObject:itemIndexPath];
    }
    
    return attr;
}

@end

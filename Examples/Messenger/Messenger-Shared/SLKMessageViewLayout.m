//
//  SLKMessageViewLayout.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 11/4/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "SLKMessageViewLayout.h"

@interface SLKMessageViewLayout()
@property (nonatomic, strong) NSMutableDictionary *rects;
@property (nonatomic) CGFloat topPadding;
@end

@implementation SLKMessageViewLayout

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    if (self){
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.sectionInset = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    self.minimumLineSpacing = 2.0;
}


#pragma mark - Getters

- (id<SLKMessageViewLayoutDelegate>)layoutDelegate
{
    return (id<SLKMessageViewLayoutDelegate>)self.collectionView.delegate;
}

- (NSInteger)numberOfItemsInAllSections
{
    NSInteger count = 0;
    
    for (NSInteger section = 0; section < [self.collectionView numberOfSections]; section++) {
        for (NSInteger row = 0; row < [self.collectionView numberOfItemsInSection:section]; row++) {
            count ++;
        }
    }
    
    return count;
}

- (CGFloat)topPadding
{
    CGFloat viewHeight = CGRectGetHeight(self.collectionView.bounds);
    CGRect lastRect = [self.rects[[self lastIndexPath]] CGRectValue];
    
    CGFloat padding = viewHeight-CGRectGetHeight(lastRect);
    
    NSLog(@"padding : %f\n\n", padding);

    return padding;
}

- (CGPoint)originForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float maxHeight = 0.0;
    
    if (indexPath.row >= 0 && indexPath.row < [self.collectionView numberOfItemsInSection:indexPath.section]) {
        NSIndexPath *previousIdxPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
        CGRect rect = [self.rects[previousIdxPath] CGRectValue];
        
        maxHeight += CGRectGetMaxY(rect);
        maxHeight += self.minimumLineSpacing;

        if ([indexPath isEqual:[self lastIndexPath]]) {
            maxHeight += self.sectionInset.top;
            maxHeight += [self topPadding];
        }
    }

    return CGPointMake(self.sectionInset.left, maxHeight);
}

- (CGSize)sizeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.layoutDelegate && [self.layoutDelegate respondsToSelector:@selector(collectionView:heightForRowAtIndexPath:)]) {
        CGFloat height = [self.layoutDelegate collectionView:self.collectionView heightForRowAtIndexPath:indexPath];
        CGFloat hMargins = self.sectionInset.left+self.sectionInset.right;
        return CGSizeMake(CGRectGetWidth(self.collectionView.frame)-hMargins, height);
    }
    return CGSizeZero;
}

- (CGRect)frameForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect frame = CGRectZero;
    frame.origin = [self originForRowAtIndexPath:indexPath];
    frame.size = [self sizeForRowAtIndexPath:indexPath];
    return frame;
}

- (NSIndexPath *)firstIndexPath
{
    return [NSIndexPath indexPathForItem:0 inSection:0];
}

- (NSIndexPath *)lastIndexPath
{
    NSInteger section = [self.collectionView numberOfSections]-1;
    NSInteger row = [self.collectionView numberOfItemsInSection:section]-1;
    
    return [NSIndexPath indexPathForItem:row inSection:section];
}


#pragma mark - Private Methods

- (void)populateAllRects
{
    if (!_rects) {
        _rects = [NSMutableDictionary new];
    }

    for (NSInteger section = [self.collectionView numberOfSections]-1; section >= 0; section--) {
        for (NSInteger row = [self.collectionView numberOfItemsInSection:section]-1; row >= 0; row--) {
            [self populateRectForIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
}

- (void)populateRectForIndexPath:(NSIndexPath *)indexPath
{
    CGRect newFrame = [self frameForRowAtIndexPath:indexPath];
    CGRect oldFrame = [self.rects[indexPath] CGRectValue];
    
    // Skips if the new frame isn't different than the old one.
    if (CGSizeEqualToSize(newFrame.size, oldFrame.size) && CGRectGetMinY(newFrame) == CGRectGetMinY(oldFrame)) {
        return;
    }
    
    self.rects[indexPath] = [NSValue valueWithCGRect:newFrame];
}


#pragma mark - UICollectionViewLayout Subclassing Hooks

- (void)prepareLayout
{
    [super prepareLayout];
    
    [self populateAllRects];
}

- (void)invalidateLayout
{
    [super invalidateLayout];
}

- (CGSize)collectionViewContentSize
{
    [self populateAllRects];
    
    CGFloat maxHeight = 0.0;

    for (NSIndexPath *indexPath in [self.rects allKeys]) {
        CGRect frame = [self.rects[indexPath] CGRectValue];
        maxHeight += CGRectGetHeight(frame);
    }
    
    CGSize collectionViewSize = self.collectionView.frame.size;
    NSLog(@"collectionViewSize : %@", NSStringFromCGSize(collectionViewSize));

    CGSize contentSize = CGSizeMake(collectionViewSize.width, maxHeight);
    
    contentSize.height += [self topPadding];
    contentSize.height += self.sectionInset.top+self.sectionInset.bottom;
    contentSize.height += self.minimumLineSpacing * [self numberOfItemsInAllSections]-1;
    
    NSLog(@"contentSize : %@", NSStringFromCGSize(contentSize));
    
    if (contentSize.height < collectionViewSize.height) {
        contentSize.height = collectionViewSize.height;
    }
    
    NSLog(@"contentSize : %@\n\n", NSStringFromCGSize(contentSize));

    return contentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    [self populateAllRects];
    
    NSMutableArray *array = [@[] mutableCopy];

    for (NSIndexPath *indexPath in [self.rects allKeys]) {
        CGRect frame = [self.rects[indexPath] CGRectValue];
        
        if (CGRectIntersectsRect(frame, rect)) {
            [array addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
        }
    }
    return array;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.frame = [self frameForRowAtIndexPath:indexPath];
    return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    BOOL restart = !(CGSizeEqualToSize(newBounds.size, self.collectionView.frame.size));
    
    if (restart) {
        _rects = nil;
    }
    
    return restart;
}

/*

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    return [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    return [super layoutAttributesForDecorationViewOfKind:elementKind atIndexPath:indexPath];
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds
{
    return [super invalidationContextForBoundsChange:newBounds];
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes
{
    return [super shouldInvalidateLayoutForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes
{
    return [super invalidationContextForPreferredLayoutAttributes:preferredAttributes withOriginalAttributes:originalAttributes];
}

*/


#pragma mark - UICollectionViewLayout Support Hooks

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    
}

- (void)finalizeCollectionViewUpdates
{
    // called inside an animation block after the update
}

- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds
{
    // UICollectionView calls this when its bounds have changed inside an animation block before displaying cells in its new bounds
}

- (void)finalizeAnimatedBoundsChange
{
    // also called inside the animation block
}

- (void)prepareForTransitionToLayout:(UICollectionViewLayout *)newLayout
{
    // UICollectionView calls this when prior the layout transition animation on the incoming and outgoing layout
}

- (void)prepareForTransitionFromLayout:(UICollectionViewLayout *)oldLayout
{
    
}

- (void)finalizeLayoutTransition
{
    
}

@end

//
//  MessageFlowLayout.swift
//  Messenger
//
//  Created by Ignacio Romero Z. on 10/30/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

import Foundation
import UIKit

class MessageFluidLayout: UICollectionViewFlowLayout {
    
    var scrollResistanceFactor: CGFloat!
    var dynamicAnimator: UIDynamicAnimator!
    
    private var visibleIndexPathsSet: NSMutableSet!
    private var visibleHeaderAndFooterSet: NSMutableSet!
    private var latestDelta: CGFloat!
    private var interfaceOrientation: UIInterfaceOrientation!
    
    
    // MARK: initializers

    override init() {
        super.init()
        commonInit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        self.dynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)
        self.visibleIndexPathsSet = NSMutableSet.init()
        self.visibleHeaderAndFooterSet = NSMutableSet.init()
    }
    
    // MARK: UICollectionViewLayout Overrides
    
    override func prepareLayout() {
        super.prepareLayout()
        
        println("prepareLayout")
        
        // Clear all behaviors on orientation change.
        if UIApplication.sharedApplication().statusBarOrientation != self.interfaceOrientation {
            self.dynamicAnimator.removeAllBehaviors()
            self.visibleIndexPathsSet = NSMutableSet.init()
        }
        
        self.interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        
        // Need to overflow our actual visible rect slightly to avoid flickering.
        let visibleRect = CGRectInset(self.collectionView?.bounds as CGRect!, -100, -100) as CGRect!
        
        println(NSStringFromCGRect(visibleRect))
        
        let itemsInVisibleRectArray = super.layoutAttributesForElementsInRect(visibleRect) as NSArray!
        
        let itemsIndexPathsInVisibleRectSet = NSSet(array: itemsInVisibleRectArray.valueForKey("indexPath") as Array)
        
        println(itemsIndexPathsInVisibleRectSet)
        
        // Step 1: Remove any behaviors that are no longer visible.
        let noLongerVisibleBehaviors = (self.dynamicAnimator.behaviors as NSArray).filteredArrayUsingPredicate(NSPredicate(block: {
            (AnyObject, [NSObject : AnyObject]!) -> Bool in
            
            let indexPath = (AnyObject as UIAttachmentBehavior).items.first?.indexPath
            
            if itemsIndexPathsInVisibleRectSet.containsObject(indexPath!) {
                return false
            }
            return true
            
        })) as NSArray
        
        noLongerVisibleBehaviors.enumerateObjectsUsingBlock { (AnyObject: AnyObject!, index, stop) -> Void in
            
            let behavior = AnyObject as UIDynamicBehavior
            let indexPath = (AnyObject as UIAttachmentBehavior).items.first?.indexPath
            
            self.dynamicAnimator.removeBehavior(behavior)
            self.visibleIndexPathsSet.removeObject(indexPath!)
            self.visibleHeaderAndFooterSet.removeObject(indexPath!)
        }
        
        
        // Step 2: Add any newly visible behaviors.
        let newlyVisibleItems = itemsInVisibleRectArray.filteredArrayUsingPredicate(NSPredicate(block: {
            (AnyObject, [NSObject : AnyObject]!) -> Bool in
            
            let attributes = AnyObject as UICollectionViewLayoutAttributes
            
            if attributes.representedElementCategory == UICollectionElementCategory.Cell {
                return self.visibleIndexPathsSet.containsObject(attributes.indexPath!)
            }
            else if self.visibleHeaderAndFooterSet.containsObject(attributes.indexPath!) {
                return false
            }
            
            return true
            
        })) as NSArray
        
        let touchLocation = self.collectionView?.panGestureRecognizer.locationInView(self.collectionView) as CGPoint!
        
        newlyVisibleItems.enumerateObjectsUsingBlock { (AnyObject: AnyObject!, index, stop) -> Void in
            
            var attributes = AnyObject as UICollectionViewLayoutAttributes
            var center = attributes.center as CGPoint!

            let behavior = self.getSpringBehavior(attributes) as UIAttachmentBehavior
            
            if CGPointEqualToPoint(touchLocation, CGPointZero) {
                
                let scrollResistance = self.getScrollResistance(behavior, touchLocation: touchLocation)

                attributes = self.getUpdatedAttributes(attributes, scrollResistance: scrollResistance);
            }
            
            self.dynamicAnimator.addBehavior(behavior)
            
            if attributes.representedElementCategory == UICollectionElementCategory.Cell {
                self.visibleIndexPathsSet.addObject(attributes.indexPath)
            }
            else {
                self.visibleHeaderAndFooterSet.addObject(attributes.indexPath)
            }
        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        
        println("layoutAttributesForElementsInRect")
        println(self.dynamicAnimator)
        println(NSStringFromCGRect(rect))
        
        return self.dynamicAnimator.itemsInRect(rect)
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        
        println("layoutAttributesForItemAtIndexPath")

        if let dynamicLayoutAttributes = self.dynamicAnimator.layoutAttributesForCellAtIndexPath(indexPath) /*! as UICollectionViewLayoutAttributes!*/ {
            return dynamicLayoutAttributes
        }
        else {
            return super.layoutAttributesForItemAtIndexPath(indexPath)
        }
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        
        println("shouldInvalidateLayoutForBoundsChange")

        let scrollView = self.collectionView? as UIScrollView!
        let touchLocation = self.collectionView?.panGestureRecognizer.locationInView(self.collectionView) as CGPoint!
        
        var delta: CGFloat!
        
        if self.scrollDirection == UICollectionViewScrollDirection.Vertical {
            delta = newBounds.origin.y - scrollView.bounds.origin.y;
        }
        else {
            delta = newBounds.origin.x - scrollView.bounds.origin.x;
        }
        
        self.latestDelta = delta
        
        
        (self.dynamicAnimator.behaviors as NSArray).enumerateObjectsUsingBlock { (AnyObject: AnyObject!, index, stop) -> Void in
            
            let behavior = AnyObject as UIAttachmentBehavior
            let attributes = behavior.items.first as UICollectionViewLayoutAttributes
            
            let scrollResistance = self.getScrollResistance(behavior, touchLocation: touchLocation)
            
            self.dynamicAnimator.updateItemUsingCurrentState(self.getUpdatedAttributes(attributes, scrollResistance: scrollResistance))
        }
        
        return false
    }
    
    override func prepareForCollectionViewUpdates(updateItems: [AnyObject]!) {
        
        println("prepareForCollectionViewUpdates")

        super.prepareForCollectionViewUpdates(updateItems)
        
        let array = updateItems as NSArray
        
        array.enumerateObjectsUsingBlock { (AnyObject: AnyObject!, index, stop) -> Void in
            
            let indexPath = (AnyObject as UICollectionViewUpdateItem).indexPathAfterUpdate as NSIndexPath
            
            self.dynamicAnimator.layoutAttributesForCellAtIndexPath(indexPath)
            
            if let dynamicLayoutAttributes = self.dynamicAnimator.layoutAttributesForCellAtIndexPath(indexPath)! as UICollectionViewLayoutAttributes! {
                return
            }
            
            let attributes = UICollectionViewLayoutAttributes.init(forCellWithIndexPath: indexPath) as UICollectionViewLayoutAttributes
            let behavior = self.getSpringBehavior(attributes) as UIAttachmentBehavior

            self.dynamicAnimator.addBehavior(behavior)
        }
    }
    
    override func invalidateLayout() {
        
        println("invalidateLayout")

        super.invalidateLayout()
    }
    
    
    // MARK: Getters
    
    func getSpringBehavior(item: UIDynamicItem) -> UIAttachmentBehavior {
        
        let behavior = UIAttachmentBehavior(item: item, attachedToAnchor: item.center) as UIAttachmentBehavior
        behavior.length = 1.0
        behavior.damping = 0.8;
        behavior.frequency = 1.0;
        
        return behavior
    }
    
    func getScrollResistance(behavior: UIAttachmentBehavior, touchLocation: CGPoint) -> CGFloat {
        
        var distanceFromTouch: CGFloat!
        
        if self.scrollDirection == UICollectionViewScrollDirection.Vertical {
            distanceFromTouch = CGFloat(fabsf(CFloat(touchLocation.y - behavior.anchorPoint.y)))
        }
        else {
            distanceFromTouch = CGFloat(fabsf(CFloat(touchLocation.x - behavior.anchorPoint.x)))
        }
        
        if self.scrollResistanceFactor > 0 {
            return CGFloat(distanceFromTouch / self.scrollResistanceFactor);
        }
        else {
            return CGFloat(distanceFromTouch / 900.0);
        }
    }
    
    func getUpdatedAttributes(attributes: UICollectionViewLayoutAttributes, scrollResistance: CGFloat) -> UICollectionViewLayoutAttributes {
        
        if self.scrollDirection == UICollectionViewScrollDirection.Vertical {
            if self.latestDelta < 0 {
                attributes.center.y += max(self.latestDelta, self.latestDelta*scrollResistance) as CGFloat
            }
            else {
                attributes.center.y += min(self.latestDelta, self.latestDelta*scrollResistance) as CGFloat
            }
        }
        else {
            if self.latestDelta < 0 {
                attributes.center.x += max(self.latestDelta, self.latestDelta*scrollResistance) as CGFloat
            }
            else {
                attributes.center.x += min(self.latestDelta, self.latestDelta*scrollResistance) as CGFloat
            }
        }
        
        return attributes
    }
}
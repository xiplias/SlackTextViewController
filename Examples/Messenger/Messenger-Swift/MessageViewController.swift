//
//  MessageViewController.swift
//  Messenger-Swift
//
//  Created by Ignacio Romero Zurbuchen on 10/16/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

class MessageViewController: SLKTextViewController {

    var messages:NSMutableArray = NSMutableArray()
    
    override class func collectionViewLayoutForCoder(decoder: NSCoder) -> UICollectionViewLayout {
        let layout: MessageFlowLayout = MessageFlowLayout();
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: UIScreen.mainScreen().bounds.size.width-20.0, height: 60.0)
        return layout
    }
    
    override func viewDidLoad() {
        
        // In progress in branch 'swift-example'
        super.viewDidLoad()
        
        self.bounces = true
        self.undoShakingEnabled = true
        self.keyboardPanningEnabled = true
        self.inverted = false
        
        self.textView.placeholder = "Message"
        self.textView.placeholderColor = UIColor.lightGrayColor()
        
        self.leftButton.setImage(UIImage(named: "icn_upload"), forState: UIControlState.Normal)
        self.leftButton.tintColor = UIColor.grayColor()
        self.rightButton.setTitle("Send", forState: UIControlState.Normal)
        
        self.textInputbar.autoHideRightButton = true
        self.textInputbar.maxCharCount = 140
        self.textInputbar.counterStyle = SLKCounterStyle.Split
        
        self.typingIndicatorView.canResignByTouch = true

        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        self.collectionView!.backgroundColor = UIColor.whiteColor()
        
        for index in 0...101 {
            let message:NSString = LoremIpsum.wordsWithNumber(20)
            self.messages.addObject(message)
        }
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as UICollectionViewCell
        cell.backgroundColor = UIColor.blackColor()
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

//
//  MessagesCollectionViewController.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 11/4/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "MessagesCollectionViewController.h"
#import "SLKMessageViewCell.h"

#import <LoremIpsum/LoremIpsum.h>

static NSString *identifier = @"reuseIdentifier";

@interface MessagesCollectionViewController ()
@property (nonatomic, strong) NSMutableArray *messages;
@end

@implementation MessagesCollectionViewController


#pragma mark - Initializer

+ (UICollectionViewLayout *)collectionViewLayoutForCoder:(NSCoder *)decoder
{
    SLKMessageViewLayout *layout = [SLKMessageViewLayout new];
    return layout;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 5; i++) {
        NSInteger count = (arc4random() % 1)+1;
        NSString *sentence = [LoremIpsum sentencesWithNumber:count];
        [array addObject:[NSString stringWithFormat:@"#%d: %@", i, sentence]];
    }
    
    self.messages = [[NSMutableArray alloc] initWithArray:array];
    
    self.inverted = NO;
    self.textInputbar.translucent = YES;
    self.shouldScrollToBottomAfterKeyboardShows = YES;
    
    self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    
    [self.collectionView registerClass:[SLKMessageViewCell class] forCellWithReuseIdentifier:identifier];
    
    self.textView.placeholder = NSLocalizedString(@"Message", nil);
    self.textView.placeholderColor = [UIColor lightGrayColor];
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
}


#pragma mark - SLKTextViewController Events

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status
{
    // Notifies the view controller that the keyboard changed status.
    // Calling super does nothing
}

- (void)textWillUpdate
{
    // Notifies the view controller that the text will update.
    // Calling super does nothing
    
    [super textWillUpdate];
}

- (void)textDidUpdate:(BOOL)animated
{
    // Notifies the view controller that the text did update.
    // Must call super
    
    [super textDidUpdate:animated];
}

- (BOOL)canPressRightButton
{
    // Asks if the right button can be pressed
    
    return [super canPressRightButton];
}

- (void)didPressRightButton:(id)sender
{
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    // Must call super
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    
    NSString *message = [self.textView.text copy];
    
    [self.messages insertObject:message atIndex:0];
    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    
    [self.collectionView slk_scrollToBottomAnimated:YES];
    
    [super didPressRightButton:sender];
}


#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SLKMessageViewCell *cell = (SLKMessageViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.titleLabel.text = self.messages[indexPath.row];
    return cell;
}


#pragma mark SLKMessageViewLayoutDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *message = self.messages[indexPath.row];
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0],
                                 NSParagraphStyleAttributeName: paragraphStyle};
    
    CGFloat width = CGRectGetWidth(collectionView.frame);
    CGRect bounds = [message boundingRectWithSize:CGSizeMake(width, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
    
    if (message.length == 0) {
        return 0.0;
    }
    
    return roundf(CGRectGetHeight(bounds));
}


#pragma mark - View lifeterm

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    
}

@end

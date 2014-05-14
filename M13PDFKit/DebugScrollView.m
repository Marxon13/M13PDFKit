//
//  DebugScrollView.m
//  M13PDFKit
//
//  Created by Brandon McQuilkin on 5/14/14.
//  Copyright (c) 2014 Brandon McQuilkin. All rights reserved.
//

#import "DebugScrollView.h"

@implementation DebugScrollView

- (void)setContentOffset:(CGPoint)contentOffset
{
    NSLog(@"Set Content Override: %@", NSStringFromCGPoint(contentOffset));
    [super setContentOffset:contentOffset];
}

- (void)setFrame:(CGRect)frame
{
    NSLog(@"Set Frame Override: %@", NSStringFromCGRect(frame));
    [super setFrame:frame];
}

- (void)setBounds:(CGRect)bounds
{
    NSLog(@"Set Bounds Override: %@", NSStringFromCGRect(bounds));
    [super setBounds:bounds];
}

- (void)setContentSize:(CGSize)contentSize
{
    NSLog(@"Set Content Size Override: %@", NSStringFromCGSize(contentSize));
    [super setContentSize:contentSize];
}

@end

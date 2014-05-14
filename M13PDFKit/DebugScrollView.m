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

@end

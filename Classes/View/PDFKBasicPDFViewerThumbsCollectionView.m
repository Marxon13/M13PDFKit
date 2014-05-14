/*
 //  PDFKBasicPDFViewerThumbsCollectionView.m
 //  M13PDFKit
 //
 Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#import "PDFKBasicPDFViewerThumbsCollectionView.h"
#import "PDFKDocument.h"
#import "PDFKThumbView.h"
#import "PDFKThumbRequest.h"
#import "PDFKThumbCache.h"
#import <QuartzCore/QuartzCore.h>

@interface PDFKBasicPDFViewerThumbsCollectionView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
/**
 The document to load thumbs from.
 */
@property (nonatomic, strong) PDFKDocument *document;
/**
 The array of bookmarked pages to display.
 */
@property (nonatomic, strong) NSArray *bookmarkedPages;
/**
 Wether or not we are showing bookmarked pages.
 */
@property (nonatomic, assign) BOOL showBookmarkedPages;

@end

@implementation PDFKBasicPDFViewerThumbsCollectionView

- (id)initWithFrame:(CGRect)frame andDocument:(PDFKDocument *)document
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    layout.minimumLineSpacing = 10.0;
    layout.minimumInteritemSpacing = 10.0;
    
    self = [super initWithFrame:frame collectionViewLayout:layout];
    
    if (self) {
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        [self registerClass:[PDFKBasicPDFViewerThumbsCollectionViewCell class] forCellWithReuseIdentifier:@"ThumbCell"];
        _document = document;
        
        self.delegate = self;
        self.dataSource = self;
    }
    
    return self;
}

- (void)showBookmarkedPages:(BOOL)show
{
    if (show) {
        NSMutableArray *temp = [NSMutableArray array];
        
        [_document.bookmarks enumerateIndexesUsingBlock:^(NSUInteger page, BOOL *stop) {
             [temp addObject:[NSNumber numberWithInteger:page]];
         }];
        
        _bookmarkedPages = [temp copy];
        _showBookmarkedPages = YES;
        [self reloadData];
    } else {
        _showBookmarkedPages = NO;
        [self reloadData];
    }
}

- (void)scrollToPage:(NSUInteger)page
{
    if (!_showBookmarkedPages) {
        //The index path can just be based on the page number.
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(page - 1) inSection:0];
        [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    } else {
        NSInteger location = [_bookmarkedPages indexOfObject:[NSNumber numberWithUnsignedInteger:page]];
        //If it is a bookmarked page.
        if (location != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:location inSection:0];
            [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (_showBookmarkedPages ? _bookmarkedPages.count : _document.pageCount);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? CGSizeMake(93.0, 120.0) : CGSizeMake(140.0, 180);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDFKBasicPDFViewerThumbsCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:@"ThumbCell" forIndexPath:indexPath];
    NSUInteger pageToDisplay = (_showBookmarkedPages ? ((NSNumber *)_bookmarkedPages[indexPath.row]).unsignedIntegerValue : indexPath.row + 1);
    
    //Set the page number
    cell.pageNumberLabel.text = [NSString stringWithFormat:@"%li", (unsigned long)pageToDisplay];
    //Show bookmarked
    [cell showBookmark:[_document.bookmarks containsIndex:pageToDisplay]];
    //Load the thumb
    PDFKThumbRequest *request = [PDFKThumbRequest newForView:cell.thumbView fileURL:_document.fileURL password:_document.password guid:_document.guid page:pageToDisplay size:[self collectionView:self layout:self.collectionViewLayout sizeForItemAtIndexPath:indexPath]];
    UIImage *image = [[PDFKThumbCache sharedCache] thumbRequest:request priority:YES];
    
    //If from cache, will return immediatly, with UIImage object, else it is an NSNull object
    if ([image isKindOfClass:[UIImage class]]) {
        [cell.thumbView showImage:image];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    //Cancel loading if necessary, don't need to load something off screen.
    PDFKBasicPDFViewerThumbsCollectionViewCell *pageCell = (PDFKBasicPDFViewerThumbsCollectionViewCell *)cell;
    [pageCell.thumbView.operation cancel];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_showBookmarkedPages) {
        [self.pageDelegate thumbCollectionView:self didSelectPage:(indexPath.row + 1)];
    } else {
        NSInteger page = ((NSNumber *)_bookmarkedPages[indexPath.row]).integerValue;\
        [self.pageDelegate thumbCollectionView:self didSelectPage:page];
    }
}

@end

@implementation PDFKBasicPDFViewerThumbsCollectionViewCell

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    //Self
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 0.5;
    
    //Add the text label first so it is in the back.
    _pageNumberLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _pageNumberLabel.userInteractionEnabled = NO;
    _pageNumberLabel.textAlignment = NSTextAlignmentCenter;
    CGFloat fontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? 19.0f : 16.0f);
    _pageNumberLabel.font = [UIFont systemFontOfSize:fontSize];
    _pageNumberLabel.textColor = [UIColor grayColor];
    _pageNumberLabel.backgroundColor = [UIColor whiteColor];
    _pageNumberLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_pageNumberLabel];
    
    NSMutableArray *pageNumberConstraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{@"superview": self, @"label": _pageNumberLabel}] mutableCopy];
    [pageNumberConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"superview": self, @"label": _pageNumberLabel}]];
    [self addConstraints:pageNumberConstraints];
    
    //Add the thumb view
    _thumbView = [[PDFKThumbView alloc] initWithFrame:self.bounds];
    _thumbView.userInteractionEnabled = NO;
    _thumbView.backgroundColor = [UIColor clearColor];
    _thumbView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_thumbView];
    
    NSMutableArray *thumbConstraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[thumb]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{@"superview": self, @"thumb": _thumbView}] mutableCopy];
    [thumbConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[thumb]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"superview": self, @"thumb": _thumbView}]];
    [self addConstraints:thumbConstraints];
    
    //Add the bookmark view last so it is on top.
    _bookmarkView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 13, 21)];
    _bookmarkView.contentMode = UIViewContentModeTop;
    _bookmarkView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_bookmarkView];
    
    NSMutableArray *bookmarkConstraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:[bookmark(13)]-5.0-|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{@"superview": self, @"bookmark": _bookmarkView}] mutableCopy];
    [bookmarkConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bookmark(21)]" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"superview": self, @"bookmark": _bookmarkView}]];
    [self addConstraints:bookmarkConstraints];
}

- (void)showBookmark:(BOOL)show
{
    if (!show) {
        _bookmarkView.image = nil;
    } else {
        _bookmarkView.image = [[UIImage imageNamed:@"Bookmarked"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_thumbView clearForReuse];
    _pageNumberLabel.text = nil;
    _bookmarkView.image = nil;
}

@end

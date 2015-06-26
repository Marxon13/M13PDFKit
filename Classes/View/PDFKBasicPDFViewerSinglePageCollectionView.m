/*
 //  PDFKBasicPDFViewerSinglePageCollectionView.m
 //  M13PDFKit
 //
 Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "PDFKBasicPDFViewerSinglePageCollectionView.h"
#import "PDFKDocument.h"
#import "PDFKPageContentView.h"

@interface PDFKBasicPDFViewerSinglePageCollectionView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, strong) PDFKDocument *document;

@property (nonatomic, strong) NSArray *bookmarkedPages;

@end

@implementation PDFKBasicPDFViewerSinglePageCollectionView

- (id)initWithFrame:(CGRect)frame andDocument:(PDFKDocument *)document
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    layout.minimumLineSpacing = 0.0;
    layout.minimumInteritemSpacing = 0.0;
    
    self.pagingEnabled = YES;
    
    self = [super initWithFrame:frame collectionViewLayout:layout];
    
    if (self) {
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        self.showsHorizontalScrollIndicator = NO;
        
        [self registerClass:[PDFKBasicPDFViewerSinglePageCollectionViewCell class] forCellWithReuseIdentifier:@"ContentCell"];
        _document = document;
        
        self.dataSource = self;
        self.delegate = self;
    }
    
    return self;
}

- (void)displayPage:(NSUInteger)page animated:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(page - 1) inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _document.pageCount;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = self.bounds.size;
    size.height -= self.contentInset.bottom + self.contentInset.top + 1;
    
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDFKBasicPDFViewerSinglePageCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:@"ContentCell" forIndexPath:indexPath];
    
    CGRect contentSize = CGRectZero;
    contentSize.size = [self collectionView:self layout:self.collectionViewLayout sizeForItemAtIndexPath:indexPath];
    
    //Get the page number
    NSInteger page = indexPath.row + 1;
    
    cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    //Load the content
    cell.pageContentView = [[PDFKPageContentView alloc] initWithFrame:contentSize fileURL:_document.fileURL page:page password:_document.password];
        
    //Show the thumb while rendering
    [cell.pageContentView showPageThumb:_document.fileURL page:(indexPath.item + 1) password:_document.password guid:_document.guid];
    
    return cell;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //Get the current page and notify the delegate
    NSUInteger page = (scrollView.contentOffset.x + scrollView.frame.size.width) / scrollView.frame.size.width;
    
    [_singlePageDelegate singlePageCollectionView:self didDisplayPage:page];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    //Get the current page and notify the delegate
    NSUInteger page = (scrollView.contentOffset.x + scrollView.frame.size.width) / scrollView.frame.size.width;
    
    [_singlePageDelegate singlePageCollectionView:self didDisplayPage:page];
}

@end

@implementation PDFKBasicPDFViewerSinglePageCollectionViewCell

- (void)setPageContentView:(PDFKPageContentView *)pageContentView
{
    if (_pageContentView) {
        [self removeConstraints:[self constraints]];
        [_pageContentView removeFromSuperview];
    }
    
    if (pageContentView == nil) {
        return;
    }
    
    _pageContentView = pageContentView;

    [self.contentView addSubview:_pageContentView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)prepareForReuse
{
    [self setPageContentView:nil];
}

- (void)setSelected:(BOOL)selected
{
    //Do nothing
}

@end
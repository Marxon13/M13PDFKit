/*
 //  PDFKBasicPDFViewerThumbsCollectionView.h
 //  M13PDFKit
 //
 Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

@class PDFKBasicPDFViewerThumbsCollectionView;
@class PDFKThumbView;
@class PDFKDocument;

@protocol PDFKBasicPDFViewerThumbsCollectionViewDelegate <NSObject>
/**
 Lets the delegate know that the thumbs collection view did select a page.
 
 @param thumbsCollectionView The collection view.
 @param page                 The page selected.
 */
- (void)thumbCollectionView:(PDFKBasicPDFViewerThumbsCollectionView *)thumbsCollectionView didSelectPage:(NSUInteger)page;

@end

@interface PDFKBasicPDFViewerThumbsCollectionView : UICollectionView
/**
 Initalize the collection view with a frame and a reader document.
 
 @param frame    The frame of the view.
 @param document The document to display thumbnails of.
 
 @return A thumbs collection view.
 */
- (id)initWithFrame:(CGRect)frame andDocument:(PDFKDocument *)document;
/**
 Scroll so that the cell for the given page is visible.
 
 @param page The page to scroll to.
 */
- (void)scrollToPage:(NSUInteger)page;
/**
 Set wether or not to show only bookmarked pages.
 
 @param show Set to YES to show only bookmarked pages.
 */
- (void)showBookmarkedPages:(BOOL)show;
/**
 The delegate that responds to page selection.
 */
@property (nonatomic, strong) id<PDFKBasicPDFViewerThumbsCollectionViewDelegate> pageDelegate;

@end


@interface PDFKBasicPDFViewerThumbsCollectionViewCell : UICollectionViewCell
/**
 The view that will display the thumb.
 */
@property (nonatomic, strong, readonly) PDFKThumbView *thumbView;
/**
 The label that displays the page number while the thumb is loading.
 */
@property (nonatomic, strong, readonly) UILabel *pageNumberLabel;
/**
 The image view that displays the bookmark image.
 */
@property (nonatomic, strong, readonly) UIImageView *bookmarkView;
/**
 Wether or not the page is bookmarked.
 
 @param show If YES, a bookmark will be displayed.
 */
- (void)showBookmark:(BOOL)show;


@end

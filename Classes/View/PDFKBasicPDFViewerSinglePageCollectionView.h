/*
 //  PDFKBasicPDFViewerSinglePageCollectionView.h
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
@class PDFKPageContentView;
@class PDFKDocument;
@class PDFKBasicPDFViewerSinglePageCollectionView;

@protocol PDFKBasicPDFViewerSinglePageCollectionViewDelegate <NSObject>
/**
 Notifies the delegate that the collection view did display a page. This allows the main controller to update bookmarks.
 
 @param collectionView The page collection view that displayed the page.
 @param page           The page.
 */
- (void)singlePageCollectionView:(PDFKBasicPDFViewerSinglePageCollectionView *)collectionView didDisplayPage:(NSUInteger)page;

@end

@interface PDFKBasicPDFViewerSinglePageCollectionView : UICollectionView

- (id)initWithFrame:(CGRect)frame andDocument:(PDFKDocument *)document;
/**
 The current page that is being displaied.
 */
@property (nonatomic, assign, readonly) NSUInteger currentPage;
/**
 The delegate that responds to page changes.
 */
@property (nonatomic, strong) id<PDFKBasicPDFViewerSinglePageCollectionViewDelegate> singlePageDelegate;
/**
 Display the given page on the screen. (By scrolling to it.)
 
 @param page     The page to display.
 @param animated Wether or not to animate the transition.
 */
- (void)displayPage:(NSUInteger)page animated:(BOOL)animated;

@end

@interface PDFKBasicPDFViewerSinglePageCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) PDFKPageContentView *pageContentView;

@end
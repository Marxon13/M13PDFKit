/*
//  PDFKBasicPDFViewer.h
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
@class PDFKDocument;

@interface PDFKBasicPDFViewer : UIViewController

/**@name Initalization*/
/**
 Initalize the PDF viewer with a PDF Document.
 
 @param document The document to show.
 
 @return A pdf viewer with a document.
 */
- (id)initWithDocument:(PDFKDocument *)document;
/**
 This method is to be used to load a document if this view controller will be displaied via segue.
 @note If the reader already has a document, a new document will not be set.
 
 @param document The document to load.
 */
- (void)loadDocument:(PDFKDocument *)document;

/**@name Controls*/
/**
 Have the PDF viewer display the given page.
 
 @param page The number of the page to display.
 */
- (void)displayPage:(NSUInteger)page;

/**@name Properties*/

@property (nonatomic, strong, readonly) PDFKDocument *document;

/**@name Features*/
/**
 Wether or not to allow bookmarking of pages.
 */
@property (nonatomic, assign) BOOL enableBookmarks;
/**
 Wether or not to enable sharing of the PDF.
 */
@property (nonatomic, assign) BOOL enableSharing;
/**
 Wether or not to enable printinh of the PDF.
 */
@property (nonatomic, assign) BOOL enablePrinting;
/**
 Wether or not to allow opening of the file in other apps.
 */
@property (nonatomic, assign) BOOL enableOpening;
/**
 Wether or not to show the thumbnail slider at the bottom of the screen.
 */
@property (nonatomic, assign) BOOL enableThumbnailSlider;
/**
 Wether or not to allow zooming out of a page to show multiple pages.
 */
@property (nonatomic, assign) BOOL enablePreview;
/**
 If false, a done button is added to the toolbar.
 */
@property (nonatomic, assign) BOOL standalone;


@end

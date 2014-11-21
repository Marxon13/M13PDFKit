//
//	ReaderPageContentView.h
//	Reader v2.7.1
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright © 2011-2013 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import "PDFKThumbView.h"

@class PDFKPageContentView;
@class PDFKPageContent;
@class PDFKPageContentThumb;

/**
 The delegate for PDFKPageContentView.
 */
@protocol PDFKPageContentViewDelegate <NSObject>

/**
 Notifies the delegate that touches begain on the content view.
 
 @param contentView The content view that is receiving the touches.
 @param touches     The touches.
 */
- (void)contentView:(PDFKPageContentView *)contentView touchesBegan:(NSSet *)touches;

@end

/**
 The container view for the PDFKPageContent (view) that allows zooming in on the page.
 */
@interface PDFKPageContentView : UIScrollView

/**
 The PDFKPageContentView's delegate that will receive touch event information.
 */
@property (nonatomic, weak, readwrite) id <PDFKPageContentViewDelegate> contentDelegate;

/**
 Create a PDFPageContentView.
 
 @param frame   The frame of the view.
 @param fileURL The URL of the PDF file to load a page from.
 @param page    The page to load from the PDF file.
 @param phrase  The password to unlock the file if necessary.
 
 @return A PDFPageContentView.
 */
- (id)initWithFrame:(CGRect)frame fileURL:(NSURL *)fileURL page:(NSUInteger)page password:(NSString *)phrase;
/**
 Shows a preview of the page derived from the thumbnail while the full page is loaded and rendered.
 
 @param fileURL The URL of the PDF file to load a preview of.
 @param page    The page to load a preview of.
 @param phrase  The password to unlock the PDF file if necessary.
 @param guid    The GUID of the PDF document to access the cache.
 */
- (void)showPageThumb:(NSURL *)fileURL page:(NSInteger)page password:(NSString *)phrase guid:(NSString *)guid;
/**
 Process a single tap on the view.
 
 @param recognizer The gesture recognizer.
 
 @return Returns a link if one is pressed in the document.
 */
- (id)processSingleTap:(UITapGestureRecognizer *)recognizer;

/**
 Increase the zoom level by one step.
 */
- (void)zoomIncrement;
/**
 Decrease the zoom level by one step.
 */
- (void)zoomDecrement;
/**
 Reset the zoom level to 0.
 */
- (void)zoomReset;

@end

/**
 The thumb that is displayed in the content view.
 */
@interface PDFKPageContentThumb : PDFKThumbView

@end

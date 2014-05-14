//
//	ReaderMainPagebar.h
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

@class PDFKPageScrubber;
@class PDFKPageScrubberTrackControl;
@class PDFKPageScrubberThumb;
@class PDFKDocument;

/**
 The delegate protocol for the PDFKPageScrubber
 */
@protocol PDFKPageScrubberDelegate <NSObject>

@required
/**
 Notifies the delegate that the page scrubber selected a page.
 
 @param pageScrubber The page scrubber that is calling the delegate.
 @param page         The page that was selected.
 */
- (void)scrubber:(PDFKPageScrubber *)pageScrubber selectedPage:(NSInteger)page;

@end

/**
 The toolbar at the bottom that allows page scrubbing.
 */
@interface PDFKPageScrubber : UIToolbar

/**
 The scrubber's delegate.
 */
@property (nonatomic, weak, readwrite) id <PDFKPageScrubberDelegate> scrubberDelegate;

/**
 Initalize the scrubber with the given frame and document.
 
 @param frame  The frame of the scrubber.
 @param object The PDFKDocument to load.
 
 @return A new scrubber.
 */
- (id)initWithFrame:(CGRect)frame document:(PDFKDocument *)object;
/**
 Update the scrubber to display the current page (If not selected through the scrubber.
 */
- (void)updateScrubber;

@end

/**
 The control that enables the scrubber to work. It calculates the percentage that you are across the width of the control, allowing the page number to be selected.
 */
@interface PDFKPageScrubberTrackControl : UIControl

/**
 The value describing the percentage across the width of the control the last touch was.
 */
@property (nonatomic, assign, readonly) CGFloat value;

@end

/**
 The thumb view to display in the page bar.
 */
@interface PDFKPageScrubberThumb : PDFKThumbView

/**
 Create a new thumb view.
 
 @param frame The frame of the thumb view.
 @param small The alpha value of the thumb view.
 
 @return A new thumb view.
 */
- (id)initWithFrame:(CGRect)frame small:(BOOL)small;

@end

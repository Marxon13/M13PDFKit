//
//	ReaderThumbView.h
//	Reader v2.6.0
//
//	Created by Julius Oklamcak on 2011-07-01.
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

/**
 A view that contains the thumbnail image for a page of a PDF Document.
 */
@interface PDFKThumbView : UIView
{
    @protected
	UIImageView *imageView;
}

/**
 The operation associated with the view.
 */
@property (atomic, strong, readwrite) NSOperation *operation;
/**
 The unique tag that identifies what the view is showing. It is a combonation of the page number, width, and height of the thumb. This is used to check that the view has not been reused before setting the thumbnail of the view.
 */
@property (nonatomic, assign, readwrite) NSUInteger targetTag;
/**
 Show the given image in the view.
 
 @param image The image to show.
 */
- (void)showImage:(UIImage *)image;
/**
 Set wether or not the view is currently being touched. If it is being touched, Change the view accordingly.
 
 @note This is to be implemented by the subclass.
 
 @param touched Wether or not the view is currently being touched.
 */
- (void)showTouched:(BOOL)touched;
/**
 Clear the view's properties to allow for reuse of the view.
 */
- (void)clearForReuse;

@end

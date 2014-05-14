//
//	ReaderContentPage.h
//	Reader v2.6.1
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
 The view that displays the PDF page. It is backed by a CATiledLayer
 */
@interface PDFKPageContent : UIView

/**
 Initalize the page view.
 
 @param fileURL The PDF file to load.
 @param page    The page of the pdf file to load.
 @param phrase  The password to unlock the PDF file.
 
 @return A new view containing the content for the given PDF page.
 */
- (id)initWithURL:(NSURL *)fileURL page:(NSInteger)page password:(NSString *)phrase;
/**
 Process a single tap on the view.
 
 @param recognizer The gesture recognizer that detected the single tap, for anotated links.
 
 @return The PDFKDocumentLink that was tapped.
 */
- (id)processSingleTap:(UITapGestureRecognizer *)recognizer;

@end

/**
 A object representation of a link on a PDF page.
 */
@interface PDFKDocumentLink : NSObject

/**
 The rect of the link in the page.
 */
@property (nonatomic, assign, readonly) CGRect rect;
/**
 The link's information.
 */
@property (nonatomic, assign, readonly) CGPDFDictionaryRef dictionary;
/**
 Create a new document link.
 
 @param linkRect       The rect of the link on the page.
 @param linkDictionary The link's information.
 
 @return A new document link.
 */
+ (id)newWithRect:(CGRect)linkRect dictionary:(CGPDFDictionaryRef)linkDictionary;
/**
 Create a new document link.

@param linkRect       The rect of the link on the page.
@param linkDictionary The link's information.

@return A new document link.
*/
- (id)initWithRect:(CGRect)linkRect dictionary:(CGPDFDictionaryRef)linkDictionary;

@end

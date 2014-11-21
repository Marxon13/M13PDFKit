//
//	ReaderThumbRequest.h
//	Reader v2.6.1
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PDFKThumbView;

/**
 Stores information for thumbnail retreival.
 */
@interface PDFKThumbRequest : NSObject

/**
 The URL of the pdf file associated with the request.
 */
@property (nonatomic, strong, readonly) NSURL *fileURL;
/**
 The GUID of the PDF document.
 */
@property (nonatomic, strong, readonly) NSString *guid;
/**
 The password to unlock the PDF file.
 */
@property (nonatomic, strong, readonly) NSString *password;
/**
 The key to the cache.
 */
@property (nonatomic, strong, readonly) NSString *cacheKey;
/**
 The unique identifier of the thumb. Comprised of its page number, width and height.
 */
@property (nonatomic, strong, readonly) NSString *thumbName;
/**
 The view the request is for.
 */
@property (nonatomic, strong, readwrite) PDFKThumbView *thumbView;
/**
 The unique tag of the thumb view.
 */
@property (nonatomic, assign, readonly) NSUInteger targetTag;
/**
 The page of the PDF document the request is for.
 */
@property (nonatomic, assign, readonly) NSInteger thumbPage;
/**
 The size of thumb the request is for.
 */
@property (nonatomic, assign, readonly) CGSize thumbSize;
/**
 Create a new thumb request.
 
 @param view   The view the request is for.
 @param url    The URL of the PDF file the request is for.
 @param phrase The password to unlock the file.
 @param guid   The GUID of the PDF document.
 @param page   The page the request is for.
 @param size   The size of the tumbnail to request.
 
 @return A new request.
 */
+ (id)newForView:(PDFKThumbView *)view fileURL:(NSURL *)url password:(NSString *)phrase guid:(NSString *)guid page:(NSInteger)page size:(CGSize)size;
/**
 Create a new thumb request.
 
 @param view   The view the request is for.
 @param url    The URL of the PDF file the request is for.
 @param phrase The password to unlock the file.
 @param guid   The GUID of the PDF document.
 @param page   The page the request is for.
 @param size   The size of the tumbnail to request.
 
 @return A new request.
 */
- (id)initWithView:(PDFKThumbView *)view fileURL:(NSURL *)url password:(NSString *)phrase guid:(NSString *)guid page:(NSInteger)page size:(CGSize)size;

@end

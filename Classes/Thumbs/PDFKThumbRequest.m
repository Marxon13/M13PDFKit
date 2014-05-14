//
//	ReaderThumbRequest.m
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

#import "PDFKThumbRequest.h"
#import "PDFKThumbView.h"

@implementation PDFKThumbRequest

#pragma mark ReaderThumbRequest class methods

+ (id)newForView:(PDFKThumbView *)view fileURL:(NSURL *)url password:(NSString *)phrase guid:(NSString *)guid page:(NSInteger)page size:(CGSize)size
{
	return [[PDFKThumbRequest alloc] initWithView:view fileURL:url password:phrase guid:guid page:page size:size];
}

#pragma mark ReaderThumbRequest instance methods

- (id)initWithView:(PDFKThumbView *)view fileURL:(NSURL *)url password:(NSString *)phrase guid:(NSString *)guid page:(NSInteger)page size:(CGSize)size
{
	if ((self = [super init])) // Initialize object
	{
		NSInteger w = size.width; NSInteger h = size.height;
        
		_thumbView = view;
        _thumbPage = page;
        _thumbSize = size;
		_fileURL = [url copy];
        _password = [phrase copy];
        _guid = [guid copy];
		_thumbName = [[NSString alloc] initWithFormat:@"%07ld-%04ldx%04ld", (long)page, (long)w, (long)h];
		_cacheKey = [[NSString alloc] initWithFormat:@"%@+%@", _thumbName, _guid];
		_targetTag = [_cacheKey hash]; _thumbView.targetTag = _targetTag;
	}
	return self;
}


@end

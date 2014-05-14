//
//	ReaderThumbRender.m
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

#import "PDFKThumbRenderer.h"
#import "PDFKThumbRequest.h"
#import "PDFKThumbCache.h"
#import "PDFKThumbView.h"
#import "CGPDFDocument.h"
#import <ImageIO/ImageIO.h>

@implementation PDFKThumbRenderer
{
    PDFKThumbRequest *_request;
}

- (id)initWithRequest:(PDFKThumbRequest *)request
{
	if ((self = [super initWithGUID:request.guid]))
	{
		_request = request;
	}
    
	return self;
}

- (void)cancel
{
    //Cancel and clean up
	[super cancel];
	_request.thumbView.operation = nil;
	_request.thumbView = nil;
	[[PDFKThumbCache sharedCache] removeNullForKey:_request.cacheKey];
}

- (NSURL *)thumbFileURL
{
    //Get the path for the cache
	NSFileManager *fileManager = [NSFileManager new];
	NSString *cachePath = [PDFKThumbCache thumbCachePathForGUID:_request.guid];
    [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:NULL];
	NSString *fileName = [NSString stringWithFormat:@"%@.png", _request.thumbName];
    //Assemble the url
	return [NSURL fileURLWithPath:[cachePath stringByAppendingPathComponent:fileName]];
}

- (void)main
{
    //Setup
	NSInteger page = _request.thumbPage;
    NSString *password = _request.password;
    
	CGImageRef imageRef = NULL;
    
	CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreate(_request.fileURL, password);
    
    // Check for non-NULL CGPDFDocumentRef
	if (thePDFDocRef != NULL) {
        
        //Get the page
		CGPDFPageRef thePDFPageRef = CGPDFDocumentGetPage(thePDFDocRef, page);
        
        // Check for non-NULL CGPDFPageRef
		if (thePDFPageRef != NULL) {
            
            //Get the maximumm size of the thumb
			CGFloat thumb_w = _request.thumbSize.width;
			CGFloat thumb_h = _request.thumbSize.height;
            
            //Setup for rendering
			CGRect cropBoxRect = CGPDFPageGetBoxRect(thePDFPageRef, kCGPDFCropBox);
			CGRect mediaBoxRect = CGPDFPageGetBoxRect(thePDFPageRef, kCGPDFMediaBox);
			CGRect effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect);
			NSInteger pageRotate = CGPDFPageGetRotationAngle(thePDFPageRef);
            
            //Get the rotated page size.
			CGFloat page_w = 0.0f;
            CGFloat page_h = 0.0f;
            
			switch (pageRotate)
			{
				default:
                //Given in degrees
				case 0: case 180:
				{
					page_w = effectiveRect.size.width;
					page_h = effectiveRect.size.height;
					break;
				}
                    
				case 90: case 270:
				{
					page_h = effectiveRect.size.width;
					page_w = effectiveRect.size.height;
					break;
				}
			}
            
            //Get the scale of the thumb size to the page size
			CGFloat scale_w = (thumb_w / page_w);
			CGFloat scale_h = (thumb_h / page_h);
			CGFloat scale = 0.0f;
            //Calculate the scale
			if (page_h > page_w) {
                //Portrait
				scale = ((thumb_h > thumb_w) ? scale_w : scale_h);
			} else {
                //Landscape
				scale = ((thumb_h < thumb_w) ? scale_h : scale_w);
            }
            
            //Get the new target width and height
			NSInteger target_w = (page_w * scale);
			NSInteger target_h = (page_h * scale);
            
            //The thumb should be an even amount of pixles in size? Not sure why
			if (target_w % 2) target_w--;
            if (target_h % 2) target_h--;
            
            //Scale the size for the screen scale
			target_w *= [UIScreen mainScreen].scale;
            target_h *= [UIScreen mainScreen].scale;
            
            //Rendering setup
			CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
			CGBitmapInfo bmi = (kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
			CGContextRef context = CGBitmapContextCreate(NULL, target_w, target_h, 8, 0, rgb, bmi);
            
             // Must have a valid custom CGBitmap context to draw into
			if (context != NULL) {
                
                //The rect to draw into in the context frame
				CGRect thumbRect = CGRectMake(0.0f, 0.0f, target_w, target_h);
                
                //Fill the rect
                CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
                CGContextFillRect(context, thumbRect);
                
                //Transform the page ref to draw into the rect.
				CGContextConcatCTM(context, CGPDFPageGetDrawingTransform(thePDFPageRef, kCGPDFCropBox, thumbRect, 0, true));
                
                //Render
				CGContextDrawPDFPage(context, thePDFPageRef);
                
                //Get the image
				imageRef = CGBitmapContextCreateImage(context);
                
                //Cleanup
				CGContextRelease(context);
			}
            //More cleaning
			CGColorSpaceRelease(rgb);
		}
        //Even more cleaning
		CGPDFDocumentRelease(thePDFDocRef);
	}
    
    //Create UIImage from CGImage and show it, then save thumb as PNG
	if (imageRef != NULL) {
        
		UIImage *image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        
        //Update cache
		[[PDFKThumbCache sharedCache] setObject:image forKey:_request.cacheKey];
        
        //Show the image in the target thumb view on the main thread
		if (self.isCancelled == NO)
		{
			PDFKThumbView *thumbView = _request.thumbView;
			NSUInteger targetTag = _request.targetTag;
            
            //Check that the target has not been reused.
            if (thumbView.targetTag == targetTag) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [thumbView showImage:image];
                });
            }
			
		}
        
        //Save the thumb to file.
		CFURLRef thumbURL = (__bridge CFURLRef)[self thumbFileURL];
		CGImageDestinationRef thumbRef = CGImageDestinationCreateWithURL(thumbURL, (CFStringRef)@"public.png", 1, NULL);
        
		if (thumbRef != NULL)
		{
            //Write to file
			CGImageDestinationAddImage(thumbRef, imageRef, NULL);
			CGImageDestinationFinalize(thumbRef);
            //Cleanup
			CFRelease(thumbRef);
		}
        //Cleanup
		CGImageRelease(imageRef);
	} else  {
        //No image - so remove the placeholder object from the cache
		[[PDFKThumbCache sharedCache] removeNullForKey:_request.cacheKey];
	}
    
    //Done!
	_request.thumbView.operation = nil;
}

@end

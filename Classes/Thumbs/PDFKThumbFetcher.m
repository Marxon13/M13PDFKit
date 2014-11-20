//
//	ReaderThumbFetch.m
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

#import "PDFKThumbFetcher.h"
#import "PDFKThumbRenderer.h"
#import "PDFKThumbCache.h"
#import "PDFKThumbView.h"
#import "PDFKThumbRequest.h"
#import <ImageIO/ImageIO.h>

@implementation PDFKThumbFetcher
{
    PDFKThumbRequest *request;
}

#pragma mark ReaderThumbFetch instance methods

- (id)initWithRequest:(PDFKThumbRequest *)options
{
	if ((self = [super initWithGUID:options.guid])) {
		request = options;
	}
	return self;
}

- (void)cancel
{
    //Cancel and clean up
	[super cancel];
	request.thumbView.operation = nil;
	request.thumbView = nil;
	[[PDFKThumbCache sharedCache] removeNullForKey:request.cacheKey];
}

- (NSURL *)thumbFileURL
{
    //Get the path to the png file.
	NSString *cachePath = [PDFKThumbCache thumbCachePathForGUID:request.guid];
	NSString *fileName = [NSString stringWithFormat:@"%@.png", request.thumbName];
	return [NSURL fileURLWithPath:[cachePath stringByAppendingPathComponent:fileName]];
}

- (void)main
{
    
	CGImageRef imageRef = NULL;
    
    //Get the existing thumb image
    //Get the URL of the file to load.
    NSURL *thumbURL = [self thumbFileURL];
	CGImageSourceRef loadRef = CGImageSourceCreateWithURL((__bridge CFURLRef)thumbURL, NULL);
    
    //If the image file exists, load it
	if (loadRef != NULL) {
		imageRef = CGImageSourceCreateImageAtIndex(loadRef, 0, NULL); // Load it
		CFRelease(loadRef);
        
	} else {
        // Existing thumb image not found - so create and queue up a thumb render operation on the work queue
		PDFKThumbRenderer *thumbRender = [[PDFKThumbRenderer alloc] initWithRequest:request];
		[thumbRender setQueuePriority:self.queuePriority];
        [thumbRender setQualityOfService:NSQualityOfServiceUserInteractive];
		if (self.isCancelled == NO) {
            // We're not cancelled - so update things and add the render operation to the work queue
            
            // Update the thumb view operation property to the new operation
			request.thumbView.operation = thumbRender;
            //Queue the operation
			[[PDFKThumbQueue sharedQueue] addWorkOperation:thumbRender];
            return;
		}
	}
    
    //Create a UIImage from a CGImage and show it
	if (imageRef != NULL) {
        
		UIImage *image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        // Release the CGImage reference from the above thumb load code
		CGImageRelease(imageRef);
        
        //Decode and draw the image on this background thread, The image is not decoded until it is drawn, Lets get it decoded now.
		UIGraphicsBeginImageContextWithOptions(image.size, YES, [UIScreen mainScreen].scale);
		[image drawAtPoint:CGPointZero];
		UIImage *decoded = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
        
        //Cache
		[[PDFKThumbCache sharedCache] setObject:decoded forKey:request.cacheKey];
        
        //Show the image in the target thumb view on the main thread
		if (self.isCancelled == NO) {
			PDFKThumbView *thumbView = request.thumbView;
			NSUInteger targetTag = request.targetTag;
            //If the view's target has not changed, display the thumb.
            if (thumbView.targetTag == targetTag) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [thumbView showImage:decoded];
                });
            }
		}
	}
    
    //Cleanup
	request.thumbView.operation = nil;
}

@end

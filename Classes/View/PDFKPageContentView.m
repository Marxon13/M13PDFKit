//
//	ReaderPageContentView.m
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

#import "PDFKPageContentView.h"
#import "PDFKPageContent.h"
#import "PDFKThumbCache.h"
#import "PDFKThumbRequest.h"
#import <QuartzCore/QuartzCore.h>

#define CONTENT_INSET 2.0f
#define ZOOM_FACTOR 2.0f
#define ZOOM_MAXIMUM 16.0f
#define PAGE_THUMB_LARGE 240
#define PAGE_THUMB_SMALL 144

@interface PDFKPageContentView () <UIScrollViewDelegate>

@end

@implementation PDFKPageContentView
{
	PDFKPageContent *theContentView;
	PDFKPageContentThumb *theThumbView;
	UIView *theContainerView;
}

static void *PDFKPageContentViewContext = &PDFKPageContentViewContext;

static inline CGFloat ZoomScaleThatFits(CGSize target, CGSize source)
{
	CGFloat w_scale = (target.width / source.width);
	CGFloat h_scale = (target.height / source.height);
	return ((w_scale < h_scale) ? w_scale : h_scale);
}

- (void)updateMinimumMaximumZoom
{
	CGRect targetRect = CGRectInset(self.bounds, 0, 0);
	CGFloat zoomScale = ZoomScaleThatFits(targetRect.size, theContentView.bounds.size);
    //Set the minimum and maximum zoom scales
	self.minimumZoomScale = zoomScale;
	self.maximumZoomScale = (zoomScale * ZOOM_MAXIMUM);
}

- (id)initWithFrame:(CGRect)frame fileURL:(NSURL *)fileURL page:(NSUInteger)page password:(NSString *)phrase
{
	if ((self = [super initWithFrame:frame]))
	{
		self.scrollsToTop = NO;
		self.delaysContentTouches = NO;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = YES;
		self.autoresizesSubviews = NO;
        self.pagingEnabled = NO;
		self.bouncesZoom = YES;
		self.delegate = self;
        self.scrollEnabled = YES;
        self.clipsToBounds = YES;
        
		theContentView = [[PDFKPageContent alloc] initWithURL:fileURL page:page password:phrase];
        
		if (theContentView != nil)
        {
			theContainerView = [[UIView alloc] initWithFrame:theContentView.bounds];
            theContainerView.backgroundColor = [UIColor blueColor];
			theContainerView.userInteractionEnabled = NO;
			theContainerView.contentMode = UIViewContentModeRedraw;
			theContainerView.backgroundColor = [UIColor whiteColor];
            theContainerView.autoresizesSubviews = YES;
            theContainerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            //Remove autoresizing constraints.
            theContentView.translatesAutoresizingMaskIntoConstraints = NO;
            theThumbView.translatesAutoresizingMaskIntoConstraints = NO;
            
            //Content size same as view size
			self.contentSize = theContentView.bounds.size;
            
            //Add the thumb view to the container view
			theThumbView = [[PDFKPageContentThumb alloc] initWithFrame:theContentView.bounds]; // Page thumb view
			[theContainerView addSubview:theThumbView];
            
            //Add the content view to the container view
			[theContainerView addSubview:theContentView];
            
            //Add the container view to the scroll view
			[self addSubview:theContainerView];
            
            //Update the minimum and maximum zoom scales
			[self updateMinimumMaximumZoom];
            
            //Set zoom to fit page content
			self.zoomScale = self.minimumZoomScale;
		}
        
		[self addObserver:self forKeyPath:@"frame" options:0 context:PDFKPageContentViewContext];
        
        //Tag the view with the page number
		self.tag = page;
	}
    
	return self;
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"frame" context:PDFKPageContentViewContext];
}

- (void)showPageThumb:(NSURL *)fileURL page:(NSInteger)page password:(NSString *)phrase guid:(NSString *)guid
{
    //Page thumb size
	BOOL large = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
	CGSize size = (large ? CGSizeMake(PAGE_THUMB_LARGE, PAGE_THUMB_LARGE) : CGSizeMake(PAGE_THUMB_SMALL, PAGE_THUMB_SMALL));
    
	PDFKThumbRequest *request = [PDFKThumbRequest newForView:theThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];
    
    //Request the page thumb
	UIImage *image = [[PDFKThumbCache sharedCache] thumbRequest:request priority:YES];
    
    // Show image from cache
	if ([image isKindOfClass:[UIImage class]]) [theThumbView showImage:image];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //Reset the zoom on frame change.
    //Our context
	if (context == PDFKPageContentViewContext) {
        
		if ((object == self) && [keyPath isEqualToString:@"frame"]) {
			CGFloat oldMinimumZoomScale = self.minimumZoomScale;
            //Update zoom scale limits
			[self updateMinimumMaximumZoom];
            
            //Old minimum
			if (self.zoomScale == oldMinimumZoomScale) {
				self.zoomScale = self.minimumZoomScale;
			} else {
                // Check against minimum zoom scale
				if (self.zoomScale < self.minimumZoomScale) {
					self.zoomScale = self.minimumZoomScale;
				} else {
                    // Check against maximum zoom scale
					if (self.zoomScale > self.maximumZoomScale) {
						self.zoomScale = self.maximumZoomScale;
					}
				}
			}
		}
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    
    //Center the content when zoomed out
	CGSize boundsSize = self.bounds.size;
	CGRect viewFrame = theContainerView.frame;
    
	if (viewFrame.size.width < boundsSize.width)
		viewFrame.origin.x = (((boundsSize.width - viewFrame.size.width) / 2.0f) + self.contentOffset.x);
	else
		viewFrame.origin.x = 0.0f;
    
	if (viewFrame.size.height < boundsSize.height)
		viewFrame.origin.y = (((boundsSize.height - viewFrame.size.height) / 2.0f) + self.contentOffset.y);
	else
		viewFrame.origin.y = 0.0f;
    
	theContainerView.frame = viewFrame;
    theThumbView.frame = theContainerView.bounds;
    theContentView.frame = theContainerView.bounds;
}

- (id)processSingleTap:(UITapGestureRecognizer *)recognizer
{
	return [theContentView processSingleTap:recognizer];
}

- (void)zoomIncrement
{
	CGFloat zoomScale = self.zoomScale;
    
	if (zoomScale < self.maximumZoomScale) {
		zoomScale *= ZOOM_FACTOR; // Zoom in
        
		if (zoomScale > self.maximumZoomScale) {
			zoomScale = self.maximumZoomScale;
		}
        
		[self setZoomScale:zoomScale animated:YES];
	}
}

- (void)zoomDecrement
{
	CGFloat zoomScale = self.zoomScale;
    
	if (zoomScale > self.minimumZoomScale) {
		zoomScale /= ZOOM_FACTOR; // Zoom out
        
		if (zoomScale < self.minimumZoomScale) {
			zoomScale = self.minimumZoomScale;
		}
        
		[self setZoomScale:zoomScale animated:YES];
	}
}

- (void)zoomReset
{
	if (self.zoomScale > self.minimumZoomScale) {
		self.zoomScale = self.minimumZoomScale;
	}
}

#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return theContainerView;
}

#pragma mark UIResponder instance methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event]; // Message superclass
	//[_contentDelegate contentView:self touchesBegan:touches]; // Message delegate
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event]; // Message superclass
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event]; // Message superclass
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event]; // Message superclass
}

- (void)setBounds:(CGRect)bounds
{
    //Kill it! Kill it with fire!
    //On the third page, the bounds size get set to 0 by autolayout for all pages that are created next.
    //No idea why...
    //EXPLAIN!!! EXPLAIN!!! EXPLAIN!!! Explain yourself doctor...
#warning EXPLAIN!!!
    if (bounds.size.width != 0 && bounds.size.height != 0) {
        [super setBounds: bounds];
    }
}

@end

@implementation PDFKPageContentThumb

#pragma mark ReaderContentThumb instance methods

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		imageView.contentMode = UIViewContentModeScaleAspectFill;
		imageView.clipsToBounds = YES;
	}
	return self;
}

@end

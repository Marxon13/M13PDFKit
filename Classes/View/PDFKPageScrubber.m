//
//	ReaderMainPagebar.m
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

#import "PDFKPageScrubber.h"
#import "PDFKDocument.h"
#import "PDFKThumbRequest.h"
#import "PDFKThumbCache.h"

#define THUMB_SMALL_GAP 2
#define THUMB_SMALL_WIDTH 22
#define THUMB_SMALL_HEIGHT 28
#define THUMB_LARGE_WIDTH 32
#define THUMB_LARGE_HEIGHT 42

#define PAGE_NUMBER_WIDTH 96.0f
#define PAGE_NUMBER_HEIGHT 30.0f
#define PAGE_NUMBER_SPACE 20.0f

@implementation PDFKPageScrubber
{
    /**
     The document the scrubber is scrubbing.
     */
    PDFKDocument *document;
    /**
     The scrubber's track control.
     */
    PDFKPageScrubberTrackControl *trackControl;
    /**
     The view that contains the controls in the toolbar.
     */
    UIView *containerView;
        
    NSMutableDictionary *miniThumbViews;
        
    PDFKPageScrubberThumb *pageThumbView;
    
    //The view that displays the page number for the scrubber.
    UILabel *pageNumberLabel;
    UIView *pageNumberView;
    
    NSTimer *enableTimer;
    NSTimer *trackTimer;
}

@synthesize pageNumberLabel = pageNumberLabel;

- (id)initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame document:nil];
}

- (id)initWithFrame:(CGRect)frame document:(PDFKDocument *)object
{
    //Must have a valid ReaderDocument
	assert(object != nil);
    
	if ((self = [super initWithFrame:frame])) {
        
        self.clipsToBounds = NO;
        
        CGFloat containerWidth = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height;
        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerWidth - (PAGE_NUMBER_SPACE * 2), 44.0)];
        
		containerView.autoresizesSubviews = YES;
		containerView.userInteractionEnabled = YES;
		containerView.contentMode = UIViewContentModeRedraw;
		containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		containerView.backgroundColor = [UIColor clearColor];
        
        UIBarButtonItem *containerItem = [[UIBarButtonItem alloc] initWithCustomView:containerView];
        [self setItems:@[containerItem]];
        
        //Create the page number's view.
		CGFloat numberY = (0.0f - (PAGE_NUMBER_HEIGHT + PAGE_NUMBER_SPACE));
		CGFloat numberX = ((containerView.bounds.size.width - PAGE_NUMBER_WIDTH) / 2.0f);
		CGRect numberRect = CGRectMake(numberX, numberY, PAGE_NUMBER_WIDTH, PAGE_NUMBER_HEIGHT);
        
        // Page numbers view
		pageNumberView = [[UIView alloc] initWithFrame:numberRect];
        
		pageNumberView.autoresizesSubviews = NO;
		pageNumberView.userInteractionEnabled = NO;
        pageNumberView.clipsToBounds = YES;
		pageNumberView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        UIToolbar *pageNumberToolbar = [[UIToolbar alloc] initWithFrame:CGRectInset(pageNumberView.bounds, -2, -2)];
        [pageNumberView addSubview:pageNumberToolbar];
        
		CGRect textRect = CGRectInset(pageNumberView.bounds, 4.0f, 2.0f); // Inset the text a bit
        
        //Create the page number label for the view.
		pageNumberLabel = [[UILabel alloc] initWithFrame:textRect]; // Page numbers label
        
		pageNumberLabel.autoresizesSubviews = NO;
		pageNumberLabel.autoresizingMask = UIViewAutoresizingNone;
		pageNumberLabel.textAlignment = NSTextAlignmentCenter;
		pageNumberLabel.backgroundColor = [UIColor clearColor];
		pageNumberLabel.textColor = [UIColor darkTextColor];
		pageNumberLabel.font = [UIFont systemFontOfSize:16.0f];
		pageNumberLabel.adjustsFontSizeToFitWidth = YES;
		pageNumberLabel.minimumScaleFactor = 0.75f;
        
		[pageNumberView addSubview:pageNumberLabel];
        
		[containerView addSubview:pageNumberView]; // Add page numbers display view
        
		trackControl = [[PDFKPageScrubberTrackControl alloc] initWithFrame:containerView.bounds]; // Track control view
        
		[trackControl addTarget:self action:@selector(trackViewTouchDown:) forControlEvents:UIControlEventTouchDown];
		[trackControl addTarget:self action:@selector(trackViewValueChanged:) forControlEvents:UIControlEventValueChanged];
		[trackControl addTarget:self action:@selector(trackViewTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
		[trackControl addTarget:self action:@selector(trackViewTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        
		[containerView addSubview:trackControl]; // Add the track control and thumbs view
        
		document = object; // Retain the document object for our use
        
		[self updatePageNumberText:document.currentPage];
        
		miniThumbViews = [NSMutableDictionary new]; // Small thumbs
	}
    
	return self;
}

- (UIColor *)thumbBackgroundColor {
    if (!_thumbBackgroundColor) {
        return [UIColor colorWithWhite:0.8 alpha:1];
    }
    return _thumbBackgroundColor;
}

- (void)removeFromSuperview
{
    //Invalidate timers
	[trackTimer invalidate];
    [enableTimer invalidate];
    
	[super removeFromSuperview];
}

- (void)updatePageThumbView:(NSInteger)page
{
	NSInteger pages = document.pageCount;
    
    //Only update frame if more than one page
	if (pages > 1) {
		CGFloat controlWidth = trackControl.bounds.size.width;
		CGFloat useableWidth = (controlWidth - THUMB_LARGE_WIDTH);
        
        //Page stride
		CGFloat stride = (useableWidth / (pages - 1));
		NSInteger X = (stride * (page - 1));
        CGFloat pageThumbX = X;
        
        //Current frame
		CGRect pageThumbRect = pageThumbView.frame;
        if (pageThumbX != pageThumbRect.origin.x) {
            //Update the frame
			pageThumbRect.origin.x = pageThumbX;
			pageThumbView.frame = pageThumbRect;
		}
	}
    
    //Only if page number changed
	if (page != pageThumbView.tag) {
        //Reuse the thumb view
		pageThumbView.tag = page;
        [pageThumbView clearForReuse];
        
        //Maximum thumb size
		CGSize size = CGSizeMake(THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT);
        
        //Get the thumb for the page.
		NSURL *fileURL = document.fileURL;
        NSString *guid = document.guid;
        NSString *phrase = document.password;
        
		PDFKThumbRequest *request = [PDFKThumbRequest newForView:pageThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];
        
        //Request the thumb
		UIImage *image = [[PDFKThumbCache sharedCache] thumbRequest:request priority:YES];
        
        //Display
		UIImage *thumb = ([image isKindOfClass:[UIImage class]] ? image : nil);
        [pageThumbView showImage:thumb];
	}
}

- (void)layoutSubviews
{
    //Update the containerview frame for the current bounds.
    CGFloat containerWidth = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.height;
    containerView.frame = CGRectMake(0, 0, containerWidth - (PAGE_NUMBER_SPACE * 2), 44.0);
    
    [super layoutSubviews];
    
    //Calculate number of thumbs to display
	CGRect controlRect = CGRectInset(containerView.bounds, 4.0f, 0.0f);
	CGFloat thumbWidth = (THUMB_SMALL_WIDTH + THUMB_SMALL_GAP);
	NSInteger thumbs = (controlRect.size.width / thumbWidth);
    
	NSInteger pages = document.pageCount;
    
    // No more than total pages
	if (thumbs > pages) thumbs = pages;
    
    //Update control width
	CGFloat controlWidth = ((thumbs * thumbWidth) - THUMB_SMALL_GAP);
	controlRect.size.width = controlWidth;
    
	CGFloat widthDelta = (containerView.bounds.size.width - controlWidth);
	NSInteger X = (widthDelta / 2.0f);
    controlRect.origin.x = X;
    //Update track control frame
	trackControl.frame = controlRect;
    
    //Create the page thumb view when needed
	if (pageThumbView == nil) {
		CGFloat heightDelta = (controlRect.size.height - THUMB_LARGE_HEIGHT);
        
        //Thumb X, Y
		NSInteger thumbY = (heightDelta / 2.0f);
        NSInteger thumbX = 0;
        
		CGRect thumbRect = CGRectMake(thumbX, thumbY, THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT);
        
        //Create the thumb view
		pageThumbView = [[PDFKPageScrubberThumb alloc] initWithFrame:thumbRect small:NO andColor:self.thumbBackgroundColor];
        //Z position so that it sits on top of the small thumbs
		pageThumbView.layer.zPosition = 1.0f;
        //Add as the first subview of the track control
		[trackControl addSubview:pageThumbView];
	}
    
    //Update page thumb view
	[self updatePageThumbView:document.currentPage];
    
	NSInteger strideThumbs = (thumbs - 1);
    if (strideThumbs < 1) strideThumbs = 1;
    
    //Page stride
	CGFloat stride = ((CGFloat)pages / (CGFloat)strideThumbs);
    
	CGFloat heightDelta = (controlRect.size.height - THUMB_SMALL_HEIGHT);
    
    //Initial X, Y
	NSInteger thumbY = (heightDelta / 2.0f);
    NSInteger thumbX = 0;
    
	CGRect thumbRect = CGRectMake(thumbX, thumbY, THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT);
    
	NSMutableDictionary *thumbsToHide = [miniThumbViews mutableCopy];
    
    //Iterate through needed thumbs
	for (NSInteger thumb = 0; thumb < thumbs; thumb++) {
        
        // Page
		NSInteger page = ((stride * thumb) + 1);
        if (page > pages) page = pages;
        
        //Page number key for thumb view
		NSNumber *key = [NSNumber numberWithInteger:page];
        
		PDFKPageScrubberThumb *smallThumbView = [miniThumbViews objectForKey:key];
        
        //We need to create a new small thumb view for the page number
		if (smallThumbView == nil) {
            //Maximum thumb size
			CGSize size = CGSizeMake(THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT);
            
			NSURL *fileURL = document.fileURL;
            NSString *guid = document.guid;
            NSString *phrase = document.password;
            
            //Create a small thumb view
			smallThumbView = [[PDFKPageScrubberThumb alloc] initWithFrame:thumbRect small:YES andColor:self.thumbBackgroundColor];
			PDFKThumbRequest *thumbRequest = [PDFKThumbRequest newForView:smallThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];
            
            //Request the thumb
			UIImage *image = [[PDFKThumbCache sharedCache] thumbRequest:thumbRequest priority:NO];
            
            //Use thumb image from cache, and show it
			if ([image isKindOfClass:[UIImage class]]) [smallThumbView showImage:image];
            
			[trackControl addSubview:smallThumbView];
            [miniThumbViews setObject:smallThumbView forKey:key];
            
		} else {
            // Resue existing small thumb view for the page number
			smallThumbView.hidden = NO;
            [thumbsToHide removeObjectForKey:key];
            
			if (CGRectEqualToRect(smallThumbView.frame, thumbRect) == false) {
				smallThumbView.frame = thumbRect;
			}
		}
        
        //Next thumb X position
		thumbRect.origin.x += thumbWidth;
	}
    
    //Hide unused thumbs
	[thumbsToHide enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        PDFKPageScrubberThumb *thumb = object;
        thumb.hidden = YES;
     }];
}

- (void)updateScrubber
{
    [self updatePagebarViews];
}

- (void)updatePagebarViews
{
	NSInteger page = document.currentPage;
    
    //Update views to corespond to the current page.
	[self updatePageNumberText:page];
	[self updatePageThumbView:page];
}

- (void)updatePageNumberText:(NSInteger)page
{
    //If the page number has changed
	if (page != pageNumberLabel.tag) {
        
		NSInteger pages = document.pageCount;
        
        //Create the string
		NSString *format = NSLocalizedString(@"%i of %i", @"format");
		NSString *number = [NSString stringWithFormat:format, page, pages]; // Text

        // Update the page number label text and last page number tag
		pageNumberLabel.text = number;
		pageNumberLabel.tag = page;
	}
}

#pragma mark ReaderTrackControl action methods

- (void)trackTimerFired:(NSTimer *)timer
{
	[trackTimer invalidate]; trackTimer = nil; // Cleanup timer
    
	if (trackControl.tag != document.currentPage) // Only if different
	{
		[_scrubberDelegate scrubber:self selectedPage:trackControl.tag]; // Go to document page
	}
}

- (void)enableTimerFired:(NSTimer *)timer
{
    //Cleanup timer
	[enableTimer invalidate];
    enableTimer = nil;
    
    //Enable track control interaction
	trackControl.userInteractionEnabled = YES;
}

- (void)restartTrackTimer
{
    //Invalidate and release previous timer
	if (trackTimer != nil) {
        [trackTimer invalidate];
        trackTimer = nil;
    }
    
	trackTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(trackTimerFired:) userInfo:nil repeats:NO];
}

- (void)startEnableTimer
{
	if (enableTimer != nil) { [enableTimer invalidate]; enableTimer = nil; } // Invalidate and release previous timer
    
	enableTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(enableTimerFired:) userInfo:nil repeats:NO];
}

- (NSInteger)trackViewPageNumber:(PDFKPageScrubberTrackControl *)trackView
{
	CGFloat controlWidth = trackView.bounds.size.width;
	CGFloat stride = (controlWidth / document.pageCount);
    
    //Get the page number.
	NSInteger page = (trackView.value / stride); // Integer page number
    
	return (page + 1); // + 1
}

- (void)trackViewTouchDown:(PDFKPageScrubberTrackControl *)trackView
{
	NSInteger page = [self trackViewPageNumber:trackView];
    
	if (page != document.currentPage) {
        //Update
		[self updatePageNumberText:page];
		[self updatePageThumbView:page];
        //Start tracking.
		[self restartTrackTimer];
	}
    //Start tracking
	trackView.tag = page;
}

- (void)trackViewValueChanged:(PDFKPageScrubberTrackControl *)trackView
{
	NSInteger page = [self trackViewPageNumber:trackView];
    
    //Only if the page number has changed
	if (page != trackView.tag) {
        //Update
		[self updatePageNumberText:page];
		[self updatePageThumbView:page];
        //Update the page tracking tag
		trackView.tag = page;
        
        //Restart the track timer
		[self restartTrackTimer];
	}
}

- (void)trackViewTouchUp:(PDFKPageScrubberTrackControl *)trackView
{
    //Finish tracking
	[trackTimer invalidate];
    trackTimer = nil;
    
    //Only if the page number has changed.
	if (trackView.tag != document.currentPage)
	{
        //Disable track control interaction while the next page is loaded.
		trackView.userInteractionEnabled = NO;
        
        //Go to document page
		[_scrubberDelegate scrubber:self selectedPage:trackView.tag];
        
        //Start track control enable timer
		[self startEnableTimer];
	}
    
    //Reset page tracking
	trackView.tag = 0;
}


@end

@implementation PDFKPageScrubberTrackControl

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingNone;
		self.backgroundColor = [UIColor clearColor];
		self.exclusiveTouch = YES;
	}
    
	return self;
}

- (CGFloat)limitValue:(CGFloat)valueX
{
	CGFloat minX = self.bounds.origin.x; // 0.0f;
	CGFloat maxX = (self.bounds.size.width - 1.0f);
    
	if (valueX < minX) valueX = minX; // Minimum X
	if (valueX > maxX) valueX = maxX; // Maximum X
    
	return valueX;
}

#pragma mark UIControl subclass methods

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint point = [touch locationInView:self]; // Touch point
	_value = [self limitValue:point.x]; // Limit control value
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (self.touchInside == YES) {
		CGPoint point = [touch locationInView:touch.view]; // Touch point
		CGFloat x = [self limitValue:point.x]; // Potential new control value
		if (x != _value) {
			_value = x;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
		}
	}
    
	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint point = [touch locationInView:self]; // Touch point
	_value = [self limitValue:point.x]; // Limit control value
}

@end

@implementation PDFKPageScrubberThumb

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame small:NO andColor:[UIColor colorWithWhite:0.8 alpha:0]];
}

- (id)initWithFrame:(CGRect)frame small:(BOOL)small andColor:(UIColor *)color
{
	if ((self = [super initWithFrame:frame]))
	{
		CGFloat value = (small ? 0.6f : 0.7f); // Size based alpha value
		UIColor *background = [color colorWithAlphaComponent:value];
        
		self.backgroundColor = background;
        imageView.backgroundColor = background;
		imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
		imageView.layer.borderWidth = 0.5f; // Give the thumb image view a border
	}
    
	return self;
}


@end


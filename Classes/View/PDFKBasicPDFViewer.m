/*
 //  PDFKBasicPDFViewer.m
 //  M13PDFKit
 //
 Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "PDFKBasicPDFViewer.h"
#import "PDFKDocument.h"
#import "PDFKPageScrubber.h"
#import "PDFKPageContentView.h"
#import "PDFKBasicPDFViewerThumbsCollectionView.h"
#import "PDFKBasicPDFViewerSinglePageCollectionView.h"
#import <TTOpenInAppActivity/TTOpenInAppActivity.h>


@interface PDFKBasicPDFViewer () <UIToolbarDelegate, UIDocumentInteractionControllerDelegate, PDFKPageScrubberDelegate, UIGestureRecognizerDelegate, PDFKBasicPDFViewerThumbsCollectionViewDelegate, PDFKBasicPDFViewerSinglePageCollectionViewDelegate>

@property (nonatomic, retain, readwrite) UIToolbar *navigationToolbar;
@property (nonatomic, retain, readwrite) UIToolbar *thumbnailSlider;
@property (nonatomic, strong, readwrite) UIBarButtonItem *shareItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *bookmarkItem;
@property (nonatomic, strong, readwrite) PDFKPageScrubber *pageScrubber;
@property (nonatomic, strong, readwrite) PDFKBasicPDFViewerSinglePageCollectionView *pageCollectionView;
@property (nonatomic, assign, readwrite) BOOL showingSinglePage;
@property (nonatomic, strong, readwrite) PDFKBasicPDFViewerThumbsCollectionView *thumbsCollectionView;
@property (nonatomic, assign, readwrite) BOOL showingBookmarks;
@property (nonatomic, assign, readwrite) BOOL loadedView;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;

@end


@implementation PDFKBasicPDFViewer

#pragma mark - Initalization and Loading

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (id)initWithDocument:(PDFKDocument *)document
{
    self = [super init];
    if (self) {
        _document = document;
    }
    return self;
}

- (void)loadDocument:(PDFKDocument *)document
{
    if (!_loadedView) {
        //Don't load yet. Need view did load to be called first.
        _document = document;
        return;
    }
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    //Defaults
    _document = document;
    
    //Create the thumbs view
    _thumbsCollectionView = [[PDFKBasicPDFViewerThumbsCollectionView alloc] initWithFrame:self.view.bounds andDocument:_document];
    _thumbsCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_thumbsCollectionView];
    _thumbsCollectionView.pageDelegate = self;
    //Set the constraints on the collection view.
    NSMutableArray *thumbsConstraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{@"superview": self.view, @"collectionView": _thumbsCollectionView}] mutableCopy];
    [thumbsConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"superview": self.view, @"collectionView": _thumbsCollectionView}]];
    [self.view addConstraints:thumbsConstraints];
    //Set the content insets, Need to account for top bar, navigation toolbar, and bottom bar.
    _thumbsCollectionView.hidden = YES;
    _showingSinglePage = YES;
    
    //Create the single page view
    _pageCollectionView = [[PDFKBasicPDFViewerSinglePageCollectionView alloc] initWithFrame:self.view.bounds andDocument:_document];
    _pageCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _pageCollectionView.singlePageDelegate = self;
    [self.view addSubview:_pageCollectionView];
    //set constraints
    NSMutableArray *pageConstraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{@"superview": self.view, @"collectionView": _pageCollectionView}] mutableCopy];
    [pageConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"superview": self.view, @"collectionView": _pageCollectionView}]];
    [self.view addConstraints:pageConstraints];
    
    //Create the navigation bar.
    _navigationToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0)];
    _navigationToolbar.delegate = self;
    //Set this to no, cant have autoresizing masks and layout constraints at the same time.
    _navigationToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    //Add to the view
    [self.view addSubview:_navigationToolbar];
    //Create the constraints.
    NSMutableArray *navigationToolbarConstraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[toolbar]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{@"superview": self.view, @"toolbar": _navigationToolbar}] mutableCopy];
    [navigationToolbarConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayout]-0-[toolbar(44)]" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"toolbar": _navigationToolbar, @"topLayout": self.topLayoutGuide}]];
    [self.view addConstraints:navigationToolbarConstraints];
    //Finish setup
    [_navigationToolbar sizeToFit];
    [self resetNavigationToolbar];
    
    //Create the scrubber
    _pageScrubber = [[PDFKPageScrubber alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - self.bottomLayoutGuide.length, self.view.frame.size.width, 44.0) document:_document];
    _pageScrubber.scrubberDelegate = self;
    _pageScrubber.delegate = self;
    //Set this to no, cant have autoresizing masks and layout constraints at the same time.
    _pageScrubber.translatesAutoresizingMaskIntoConstraints = NO;
    //Add to the view
    [self.view addSubview:_pageScrubber];
    //Create the constraints
    NSMutableArray *pageScrubberConstraints = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrubber]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{@"superview": self.view, @"scrubber": _pageScrubber}] mutableCopy];
    [pageScrubberConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[scrubber(44)]-0-[bottomLayout]" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"scrubber": _pageScrubber, @"bottomLayout": self.bottomLayoutGuide}]];
    [self.view addConstraints:pageScrubberConstraints];
    //Finish
    [_pageScrubber sizeToFit];
    
    //Add the tap gesture recognizers
    //Next page, previous page, handle link, handle toggle toolbars
    _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    _singleTapGestureRecognizer.numberOfTapsRequired = 1;
    _singleTapGestureRecognizer.numberOfTouchesRequired = 1;
    _singleTapGestureRecognizer.cancelsTouchesInView = YES;
    _singleTapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:_singleTapGestureRecognizer];
    
    //Handle zoom in
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    _doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    _doubleTapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:_doubleTapGestureRecognizer];
    
    [_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
    
    //Handle zoom out
    UITapGestureRecognizer *doubleTwoFingerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTwoFingerTapGestureRecognizer.numberOfTouchesRequired = 2;
    doubleTwoFingerTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTwoFingerTapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:doubleTwoFingerTapGestureRecognizer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _loadedView = YES;
    if (_document) {
        [self loadDocument:_document];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //Save the document
    [_document saveReaderDocument];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    //Doing this since querying the layout guides a second time returns 0.
    CGFloat topLayoutGuideLength = self.topLayoutGuide.length;
    CGFloat bottomLayoutGuideLength = self.bottomLayoutGuide.length;
    
    //Content insets
    _pageCollectionView.contentInset = UIEdgeInsetsMake(topLayoutGuideLength, 0, bottomLayoutGuideLength, 0);
    _thumbsCollectionView.contentInset = UIEdgeInsetsMake(topLayoutGuideLength + 44.0, 0, bottomLayoutGuideLength, 0);
    
    [_pageCollectionView.collectionViewLayout invalidateLayout];
    [_thumbsCollectionView.collectionViewLayout invalidateLayout];
    
    [self.view layoutSubviews];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    if (bar == _navigationToolbar) {
        return UIBarPositionTop;
    }
    if (bar == _pageScrubber) {
        return UIBarPositionBottom;
    }
    return UIBarPositionBottom;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [_thumbsCollectionView.collectionViewLayout invalidateLayout];
    [_pageCollectionView.collectionViewLayout invalidateLayout];
    
    [_pageCollectionView displayPage:_document.currentPage animated:NO];
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - Navigation Bar

- (void)resetNavigationToolbar
{
    NSMutableArray *buttonsArray = [NSMutableArray array];
    
    //Set controls for a single page.
    if (_showingSinglePage) {
        //Done Button
        if (!_standalone) {
            [buttonsArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)]];
            [buttonsArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        }
        
        //Add space if necessary
        if (buttonsArray.count > 0) {
            UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            space.width = 10.0;
            [buttonsArray addObject:space];
        }
        
        if(_enableThumbs == YES)
        {
            //Add list
            UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Thumbs" inBundle:[PDFKBasicPDFViewer getResourcesBundle] compatibleWithTraitCollection:nil] landscapeImagePhone:[UIImage imageNamed:@"Thumbs" inBundle:[PDFKBasicPDFViewer getResourcesBundle] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(list)];
            [buttonsArray addObject:listItem];
            
            //Flexible space
            [buttonsArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        }
        
        //Bookmark Button
        if (_enableBookmarks) {
            //Add space
            UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            space.width = 10.0;
            [buttonsArray addObject:space];
            //Add bookmarks
            //Change image based on wether or not the page is bookmarked
            if (![_document.bookmarks containsIndex:_document.currentPage]) {
                _bookmarkItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Bookmark" inBundle:[PDFKBasicPDFViewer getResourcesBundle] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(bookmark)];
            } else {
                _bookmarkItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Bookmarked" inBundle:[PDFKBasicPDFViewer getResourcesBundle] compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(bookmark)];
            }
            
            [buttonsArray addObject:_bookmarkItem];
        }
        
        //Sharing Button
        if (_enableSharing || _enablePrinting || _enableOpening) {
            UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            space.width = 10.0;
            [buttonsArray addObject:space];
            _shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(send)];
            [buttonsArray addObject:_shareItem];
        }
    } else {
        
        //Set controls for thumbs
        //Done Button
        if (!_standalone) {
            [buttonsArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)]];
            [buttonsArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        }
        
        //Add space if necessary
        if (buttonsArray.count > 0) {
            UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            space.width = 10.0;
            [buttonsArray addObject:space];
        }
        
        //Go back
        if (!self.backButtonTitle) {
            self.backButtonTitle = @"Resume";
        }
        UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithTitle:self.backButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(list)];
        [buttonsArray addObject:listItem];
        
        //Flexible space
        [buttonsArray addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        
        //Bookmarks
        
        
        UIImage *thumbsImage = [UIImage imageNamed:@"Thumbs" inBundle:[PDFKBasicPDFViewer getResourcesBundle] compatibleWithTraitCollection:nil];
        UIImage *bookmarkImage = [UIImage imageNamed:@"Bookmark" inBundle:[PDFKBasicPDFViewer getResourcesBundle] compatibleWithTraitCollection:nil];
        
        UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[thumbsImage, bookmarkImage]];
        [control setSelectedSegmentIndex:(!_showingBookmarks ? 0 : 1)];
        [control sizeToFit];
        [control addTarget:self action:@selector(toggleShowBookmarks:) forControlEvents:UIControlEventValueChanged];
        UIBarButtonItem *bookmarkItem = [[UIBarButtonItem alloc] initWithCustomView:control];
        [buttonsArray addObject:bookmarkItem];
    }
    
    [_navigationToolbar setItems:buttonsArray animated:YES];
}

#pragma mark - Actions

- (void)dismiss
{
    if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)send
{
    UIActivityViewController *activityViewController;
    TTOpenInAppActivity *openInAppActivity;
    if (_enableOpening) {
        openInAppActivity = [[TTOpenInAppActivity alloc] initWithView:self.view andBarButtonItem:_shareItem];
        activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[_document.fileURL] applicationActivities:@[openInAppActivity]];
    } else {
        activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[_document.fileURL] applicationActivities:nil];
    }
    
    if (!_enablePrinting) {
        activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard];
    }
    if (!_enableSharing) {
        NSMutableArray *array = [@[UIActivityTypeAirDrop, UIActivityTypeCopyToPasteboard, UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTencentWeibo, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo] mutableCopy];
        if (activityViewController.excludedActivityTypes.count >= 1) {
            [array addObjectsFromArray:activityViewController.excludedActivityTypes];
        }
        activityViewController.excludedActivityTypes = array;
    }
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone){
        // Show UIActivityViewController
        [self presentViewController:activityViewController animated:YES completion:NULL];
    } else {
        // Create pop up
        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        // Show UIActivityViewController in popup
        activityViewController.popoverPresentationController.sourceView = (UIView*)_shareItem;
        
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (void)bookmark
{
    if ([_document.bookmarks containsIndex:_document.currentPage]) {
        //Remove the bookmark
        [_document.bookmarks removeIndex:_document.currentPage];
    } else {
        //Add the bookmark
        [_document.bookmarks addIndex:_document.currentPage];
    }
    //Reset the toolbar
    [self resetNavigationToolbar];
}

- (void)list
{
    [self toggleSinglePageView];
}

- (void)toggleShowBookmarks:(id)sender
{
    UISegmentedControl *control = sender;
    if (control.selectedSegmentIndex == 0) {
        [_thumbsCollectionView showBookmarkedPages:NO];
    } else {
        [_thumbsCollectionView showBookmarkedPages:YES];
    }
}

#pragma mark - Page Control

- (void)thumbCollectionView:(PDFKBasicPDFViewerThumbsCollectionView *)thumbsCollectionView didSelectPage:(NSUInteger)page
{
    if (self.document.currentPage != page) {
        [self.pageCollectionView displayPage:page animated:YES];
        self.document.currentPage = page;
        [self.pageScrubber updateScrubber];
        if (_pageChangeBlock) {
            _pageChangeBlock(page);
        }
    }
    [self toggleSinglePageView];
}

- (void)scrubber:(PDFKPageScrubber *)pageScrubber selectedPage:(NSInteger)page
{
    if (self.document.currentPage != page) {
        self.document.currentPage = page;
        [self.pageCollectionView displayPage:page animated:NO];
        [self resetNavigationToolbar];
        
        if (_pageChangeBlock) {
            _pageChangeBlock(page);
        }
    }
}

- (void)singlePageCollectionView:(PDFKBasicPDFViewerSinglePageCollectionView *)collectionView didDisplayPage:(NSUInteger)page
{
    if (self.document.currentPage != page) {
        self.document.currentPage = page;
        [self.pageScrubber updateScrubber];
        [self resetNavigationToolbar];
        
        if (_pageChangeBlock) {
            _pageChangeBlock(page);
        }
    }
}

- (void)nextPage
{
    _document.currentPage += 1;
    [_pageScrubber updateScrubber];
    [_pageCollectionView displayPage:_document.currentPage animated:YES];
    [self resetNavigationToolbar];
}

- (void)previousPage
{
    _document.currentPage -= 1;
    [_pageScrubber updateScrubber];
    [_pageCollectionView displayPage:_document.currentPage animated:YES];
    [self resetNavigationToolbar];
}

- (void)displayPage:(NSUInteger)page
{
    _document.currentPage = page;
    [_pageScrubber updateScrubber];
    [_pageCollectionView displayPage:page animated:YES];
    [self resetNavigationToolbar];
}

#pragma mark - Gestures

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (!_showingSinglePage) {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint location = [touch locationInView:self.view];
    
    //We want to cancel the toggle gesture if we are on the toolbars while they are visible
    if (_navigationToolbar.hidden == NO) {
        if (CGRectContainsPoint(_navigationToolbar.frame, location) || CGRectContainsPoint(_pageScrubber.frame, location)) {
            return NO;
        }
    }
    
    return YES;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    //Check to see if the document was clicked.
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized && _showingSinglePage) {
        if (gestureRecognizer.numberOfTapsRequired == 1) {
            //Check what side the touch is on
            CGPoint touch = [gestureRecognizer locationInView:self.view];
            
            //Left side
            if (CGRectContainsPoint(CGRectMake(0, 0, self.view.frame.size.width * .33, self.view.frame.size.height), touch)) {
                [self previousPage];
                
            } else if (CGRectContainsPoint(CGRectMake(self.view.frame.size.width * .33, 0, self.view.frame.size.width * .33, self.view.frame.size.height), touch)) {
                //Center
                [self toggleToolbars];
                
            } else {
                //Right
                [self nextPage];
            }
        }
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if (gestureRecognizer.numberOfTouchesRequired == 1) {
            //Zoom in
            PDFKBasicPDFViewerSinglePageCollectionViewCell *cell = [_pageCollectionView visibleCells][0];
            [cell.pageContentView zoomIncrement];
        } else {
            //Zoom out
            PDFKBasicPDFViewerSinglePageCollectionViewCell *cell = [_pageCollectionView visibleCells][0];
            [cell.pageContentView zoomDecrement];
        }
    }
}

#pragma mark - Views

- (void)toggleToolbars
{
    if (_showingSinglePage ) {
        if (_navigationToolbar.hidden) {
            //Show toolbars
            _navigationToolbar.hidden = NO;
            _pageScrubber.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                if (_navigationToolbar.alpha == 0.0) {
                    _navigationToolbar.alpha = 1.0;
                }
                if (_pageScrubber.alpha == 0.0) {
                    _pageScrubber.alpha = 1.0;
                }
            }];
        } else {
            //Hide toolbars
            [UIView animateWithDuration:0.3 animations:^{
                if (_navigationToolbar.alpha == 1.0) {
                    _navigationToolbar.alpha = 0.0;
                }
                if (_pageScrubber.alpha == 1.0) {
                    _pageScrubber.alpha = 0.0;
                }
            } completion:^(BOOL finished) {
                if (finished) {
                    _navigationToolbar.hidden = YES;
                    _pageScrubber.hidden = YES;
                }
            }];
        }
    }
}

- (void)toggleSinglePageView
{
    if (_showingSinglePage) {
        //Show the thumbs view.
        _showingSinglePage = NO;
        [self resetNavigationToolbar];
        [_thumbsCollectionView showBookmarkedPages:NO];
        [_thumbsCollectionView reloadData];
        
        //Hide the slider if showing, show the nav bar if not showing
        _navigationToolbar.hidden = NO;
        _thumbsCollectionView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            if (_navigationToolbar.alpha == 0.0) {
                _navigationToolbar.alpha = 1.0;
            }
            if (_pageScrubber.alpha == 1.0) {
                _pageScrubber.alpha = 0.0;
            }
            if (_pageCollectionView.alpha == 1.0) {
                _pageCollectionView.alpha = 0.0;
            }
        } completion:^(BOOL finished) {
            _pageScrubber.hidden = YES;
            _pageCollectionView.hidden = YES;
        }];
    } else {
        _showingSinglePage = YES;
        [self resetNavigationToolbar];
        _pageScrubber.hidden = NO;
        _pageCollectionView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            if (_pageScrubber.alpha == 0.0) {
                _pageScrubber.alpha = 1.0;
            }
            if (_pageCollectionView.alpha == 0.0) {
                _pageCollectionView.alpha = 1.0;
            }
        } completion:^(BOOL finished) {
            //Hide so we don't have to render.
            _thumbsCollectionView.hidden = YES;
        }];
    }
}

#pragma mark - Static methods

+ (NSBundle*)getResourcesBundle
{
    NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
    NSURL *frameworkResourcesBundleUrl = [frameworkBundle URLForResource:@"M13PDFKitResources" withExtension:@"bundle"];
    NSBundle *frameworkResourcesBundle = [NSBundle bundleWithURL:frameworkResourcesBundleUrl];
    
    return frameworkResourcesBundle;
}

@end


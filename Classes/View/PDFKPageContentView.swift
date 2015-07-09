//
//  PDFKPageContentView.swift
//  M13PDFKit
//
/*
Copyright (c) 2015 Brandon McQuilkin

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation

import UIKit

private let CONTENT_INSET: CGFloat = 2.0
private let ZOOM_FACTOR: CGFloat = 2.0
private let ZOOM_MAXIMUM: CGFloat = 16.0
private let PAGE_THUMB_LARGE: CGFloat = 240.0
private let PAGE_THUMB_SMALL: CGFloat = 144.0

private typealias PDFKPageContentViewContext = UInt8
private var kPDFKPageContentViewContext = PDFKPageContentViewContext()

internal protocol PDFKPageContentViewDelegate {
    /**
    Notifies the delegate that touches begain on the content view.
    
    @param contentView The content view that is receiving the touches.
    @param touches     The touches.
    */
    func contentView(contentView: PDFKPageContent, touchesBegan touches:Set<UITouch>)
}

internal class PDFKPageContentView: UIScrollView, UIScrollViewDelegate {
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    /**
    The PDFKPageContentView's delegate that will receive touch event information.
    */
    var contentDelegate: PDFKPageContentViewDelegate?
    
    /**
    The content view.
    */
    private var theContentView: PDFKPageContent
    
    /**
    The thumb view.
    */
    private var theThumbView: PDFKPageContentThumbView
    
    /**
    Container view
    */
    private var theContainerView: UIView
    
    override var bounds: CGRect {
        willSet(newValue) {
            //Kill it! Kill it with fire!
            //On the third page, the bounds size get set to 0 by autolayout for all pages that are created next.
            //No idea why...
            //EXPLAIN!!! EXPLAIN!!! EXPLAIN!!! Explain yourself doctor...
            if newValue.size.width == 0 || newValue.size.height == 0 {
                newValue = self.bounds
            }
        }
    }
    
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------
    
    /**
    Create a PDFPageContentView.
    
    @param frame   The frame of the view.
    @param fileURL The URL of the PDF file to load a page from.
    @param page    The page to load from the PDF file.
    @param phrase  The password to unlock the file if necessary.
    
    @return A PDFPageContentView.
    */
    init(frame: CGRect, fileURL: NSURL, page: Int, password: String) {
        
        //Create the content view
        theContentView = PDFKPageContent(frame: frame, fileURL: fileURL, page: page, password: password)
        theContentView.translatesAutoresizingMaskIntoConstraints = false
        
        //Create the container view
        theContainerView = UIView(frame: theContentView.bounds)
        theContainerView.backgroundColor = UIColor.whiteColor()
        theContainerView.userInteractionEnabled = false
        theContainerView.contentMode = UIViewContentMode.Redraw
        theContainerView.autoresizesSubviews = true
        theContainerView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        theContainerView.translatesAutoresizingMaskIntoConstraints = false

        //Create the thumb view
        theThumbView = PDFKPageContentThumbView(frame: theContentView.bounds)
        theThumbView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frame)
        
        //Set defaults
        scrollsToTop = false
        delaysContentTouches = false
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentMode = UIViewContentMode.Redraw
        backgroundColor = UIColor.clearColor()
        userInteractionEnabled = true
        autoresizesSubviews = false
        pagingEnabled = false
        bouncesZoom = true
        delegate = self
        scrollEnabled = true
        clipsToBounds = true
        autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        contentSize = theContentView.bounds.size
        
        //Create view tree
        theContainerView.addSubview(theThumbView)
        theContainerView.addSubview(theContentView)
        addSubview(theContainerView)
        
        //Update
        updateMinAndMaxZoom()
        zoomScale = minimumZoomScale
        
        //Get frame updates
        addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.New, context: &kPDFKPageContentViewContext)
        
        //Tag view with page number
        self.tag = page
    }
    
    deinit {
        removeObserver(self, forKeyPath: "frame", context: &kPDFKPageContentViewContext)
    }
    
    //------------------------------------------
    /// @name Preview
    //------------------------------------------
    
    /**
    Shows a preview of the page derived from the thumbnail while the full page is loaded and rendered.
    
    @param fileURL The URL of the PDF file to load a preview of.
    @param page    The page to load a preview of.
    @param phrase  The password to unlock the PDF file if necessary.
    @param guid    The GUID of the PDF document to access the cache.
    */
    func showPageThumb(fileURL: NSURL, page: Int, password: String, guid: String) {
        //Page thumb size
        let large: Bool = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad
        let size: CGSize = large ? CGSizeMake(PAGE_THUMB_LARGE, PAGE_THUMB_LARGE) : CGSizeMake(PAGE_THUMB_SMALL, PAGE_THUMB_SMALL)
        
        if let image: UIImage = PDFKThumbCache.sharedInstance().thumbWithThumbRequest(request, hasPriority: true) {
            theThumbView.imageView.image = image
        }
    }
    
    //------------------------------------------
    /// @name Actions
    //------------------------------------------
    
    /**
    Process a single tap on the view.
    
    @param recognizer The gesture recognizer.
    
    @return Returns a link if one is pressed in the document.
    */
    func processSingleTap(recognizer: UITapGestureRecognizer) {
        theContentView.processSingleTap(recognizer)
    }
    
    /**
    Increase the zoom level by one step.
    */
    func zoomIncrement() {
        var aZoomScale = self.zoomScale
        
        aZoomScale *= ZOOM_FACTOR
        
        if aZoomScale > maximumZoomScale {
            aZoomScale = maximumZoomScale
        }
        
        self.setZoomScale(aZoomScale, animated: true)
    }
    
    /**
    Decrease the zoom level by one step.
    */
    func zoomDecrement() {
        var aZoomScale = self.zoomScale
        
        aZoomScale /= ZOOM_FACTOR
        
        if aZoomScale < minimumZoomScale {
            aZoomScale = minimumZoomScale
        }
        
        self.setZoomScale(aZoomScale, animated: true)
    }
    
    /**
    Reset the zoom level to 1.
    */
    func zoomReset() {
        zoomScale = minimumZoomScale
    }
    
    //------------------------------------------
    /// @name UIScrollViewDelegate Methods
    //------------------------------------------
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return theContentView
    }
    
    //------------------------------------------
    /// @name UIResponder
    //------------------------------------------
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
    }
    
    //------------------------------------------
    /// @name Other Methods
    //------------------------------------------
    
    /**
    Calculates the zoom level that fits the page to the scroll view.
    
    @param targetSize The target size of the page.
    @param sourceSize The size of the source.
    
    @return The scale required to fit the source page to the target.
    */
    func zoomScaleThatFits(targetSize: CGSize, sourceSize: CGSize) -> CGFloat {
        let wScale = targetSize.width / sourceSize.width
        let hScale = targetSize.height / sourceSize.height
        return wScale < hScale ? wScale : hScale
    }
    
    /**
    Update the minimum and maximum zoom values of the scroll view.
    */
    func updateMinAndMaxZoom() {
        let minZoom: CGFloat = zoomScaleThatFits(self.bounds.size, sourceSize: theContentView.bounds.size)
        minimumZoomScale = minZoom
        maximumZoomScale = minZoom * ZOOM_MAXIMUM
    }
    
    /**
    Observe frame changes.
    */
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        //Reset the zoom on frame change
        if context == &kPDFKPageContentViewContext {
            if object == self && keyPath == "frame" {
                if zoomScale < minimumZoomScale {
                    zoomScale = minimumZoomScale
                } else if zoomScale > maximumZoomScale {
                    zoomScale = maximumZoomScale
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Center the content when zoomed out
        let boundsSize: CGRect = self.bounds.size
        var viewFrame: CGRect = theContainerView.frame
        
        if viewFrame.size.width < bounds.size.width {
            viewFrame.origin.x = ((boundsSize.width - viewFrame.size.width) / 2.0) + contentOffset.x
        } else {
            viewFrame.origin.x = 0.0
        }
        
        if viewFrame.size.height < boundsSize.height {
            viewFrame.origin.y = ((boundsSize.height - viewFrame.size.height) / 2.0) + contentOffset.y
        } else {
            viewFrame.origin.y = 0.0
        }
        
        theContainerView.frame = viewFrame
        theThumbView.frame = theContainerView.bounds
        theContentView.frame = theContainerView.bounds
    }
    
}
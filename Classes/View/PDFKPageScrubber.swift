//
//  PDFKPageScrubber.swift
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

import UIKit

private let THUMB_SMALL_GAP: CGFloat = 2
private let THUMB_SMALL_WIDTH: CGFloat = 22
private let THUMB_SMALL_HEIGHT: CGFloat = 28
private let THUMB_LARGE_WIDTH: CGFloat = 32
private let THUMB_LARGE_HEIGHT: CGFloat = 42

private let PAGE_NUMBER_WIDTH: CGFloat = 6.0
private let PAGE_NUMBER_HEIGHT: CGFloat = 30.0
private let PAGE_NUMBER_SPACE: CGFloat = 20.0

/**
The delegate protocol for the PDFKPageScrubber
*/
protocol PDFKPageScrubberDelegate {
    /**
    Notifies the delegate that the page scrubber selected a page.
    
    @param pageScrubber The page scrubber that is calling the delegate.
    @param page         The page that was selected.
    */
    func scrubber(pageScrubber: PDFKPageScrubber, selectedPage page: Int)
}

/**
The toolbar at the bottom that allows page scrubbing.
*/
internal class PDFKPageScrubber: UIToolbar {
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    /**
    The scrubber's delegate.
    */
    internal var scrubberDelegate: PDFKPageScrubberDelegate?
    
    /**
    The document the scrubber is scrubbing.
    */
    private let document: PDFKDocument
    
    /**
    The scrubber's track control.
    */
    private let trackControl: PDFKPageScrubberTrackControl
    
    /**
    The view that contains the controls in the toolbar.
    */
    private let containerView: UIView
    
    /**
    The dictionary that contains the thumb views for each page.
    */
    private var miniThumbViews: [Int: PDFKPageScrubberThumbView] = [:]
    
    /**
    The larger page thumb view for the scrubber, showing the currently selected page.
    */
    private var pageThumbView: PDFKPageScrubberThumbView?
    
    /**
    The label that shows the currently selected page number.
    */
    private let pageNumberLabel: UILabel
    
    /**
    The page number view.
    */
    private let pageNumberView: UIView
    
    /**
    The timer used to delay showing the main thumb view. This is so we are not constantly rendering and canceling page renders.
    */
    private var enableTimer: NSTimer?
    
    /**
    The timer used to delay updating the main thumb view. This is so we are not constantly rendering and canceling page renders.
    */
    private var trackTimer: NSTimer?
    
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------
    
    /**
    Initalize the scrubber with the given frame and document.
    
    @param frame  The frame of the scrubber.
    @param object The PDFKDocument to load.
    
    @return A new scrubber.
    */
    init(frame: CGRect, document aDocument: PDFKDocument) {
        
        document = aDocument
        
        //Create the container view
        let containerWidth: CGFloat = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) ? UIScreen.mainScreen().bounds.size.width : UIScreen.mainScreen().bounds.size.height
        containerView = UIView(frame: CGRectMake(PAGE_NUMBER_SPACE, 0, containerWidth - (PAGE_NUMBER_SPACE * 2), 44.0))
        containerView.autoresizesSubviews = false
        containerView.userInteractionEnabled = true
        containerView.contentMode = UIViewContentMode.Redraw
        containerView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleTopMargin
        containerView.backgroundColor = UIColor.clearColor()
        
        let containerItem: UIBarButtonItem = UIBarButtonItem(customView: containerView)
        
        //Create the page number view
        let numberY: CGFloat = 0.0 - (PAGE_NUMBER_HEIGHT + PAGE_NUMBER_SPACE)
        let numberX: CGFloat = (containerView.bounds.size.width - PAGE_NUMBER_WIDTH) / 2.0
        let numberRect: CGRect = CGRectMake(numberX, numberY, PAGE_NUMBER_WIDTH, PAGE_NUMBER_HEIGHT)
        
        pageNumberView = UIView(frame: numberRect)
        pageNumberView.autoresizesSubviews = false
        pageNumberView.userInteractionEnabled = false
        pageNumberView.clipsToBounds = true
        pageNumberView.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin
        
        let pageNumberToolbar: UIToolbar = UIToolbar(frame: CGRectInset(pageNumberView.bounds, -2, -2))
        pageNumberView.addSubview(pageNumberToolbar)
        
        let textRect: CGRect = CGRectInset(pageNumberView.bounds, 4.0, 2.0)
        
        pageNumberLabel = UILabel(frame: textRect)
        pageNumberLabel.autoresizesSubviews = false
        pageNumberLabel.autoresizingMask = UIViewAutoresizing.None
        pageNumberLabel.textAlignment = NSTextAlignment.Center
        pageNumberLabel.backgroundColor = UIColor.clearColor()
        pageNumberLabel.textColor = UIColor.darkTextColor()
        pageNumberLabel.font = UIFont.systemFontOfSize(16.0)
        pageNumberLabel.adjustsFontSizeToFitWidth = true
        pageNumberLabel.minimumScaleFactor = 0.75
        
        pageNumberView.addSubview(pageNumberLabel)
        
        containerView.addSubview(pageNumberView)
        
        trackControl = PDFKPageScrubberTrackControl(frame: containerView.bounds)
        containerView.addSubview(trackControl)
        
        super.init(frame: frame)
        
        self.setItems([containerItem], animated: false)
        
        self.clipsToBounds = false
        
        trackControl.addTarget(self, action: "trackViewTouchDown:", forControlEvents: UIControlEvents.TouchDown)
        trackControl.addTarget(self, action: "trackViewValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        trackControl.addTarget(self, action: "trackViewTouchUp:", forControlEvents: UIControlEvents.TouchUpOutside)
        trackControl.addTarget(self, action: "trackViewTouchUp:", forControlEvents: UIControlEvents.TouchUpInside)
        
        updatePageNumberText(document.currentPage)
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //------------------------------------------
    /// @name Updating
    //------------------------------------------
    
    /**
    Update the scrubber to display the current page (If not selected through the scrubber.
    */
    func updateScrubber() {
        updatePagebarViews()
    }
    
    override func removeFromSuperview() {
        trackTimer?.invalidate()
        enableTimer?.invalidate()
        super.removeFromSuperview()
    }
    
    private func updatePageThumbView(page: Int) {
        //Only update frame if more than one page
        let pages: UInt = document.pageCount
        if pages > 1 {
            let controlWidth: CGFloat = trackControl.bounds.size.width
            let useableWidth: CGFloat = controlWidth - THUMB_LARGE_WIDTH
            
            //Page stride
            let stride: CGFloat = useableWidth / (CGFloat(pages) - 1.0)
            let pageThumbX: Int = Int(stride) * (page - 1)
            
            //Update the current frame
            if var pageThumbRect: CGRect = pageThumbView?.frame {
                pageThumbRect.origin.x = CGFloat(pageThumbX)
                pageThumbView?.frame = pageThumbRect
            }
            
            //Only update the image if the page number has changed.
            if let pageThumbView = pageThumbView {
                if page != pageThumbView.tag {
                    //Reuse the thumb view
                    pageThumbView.tag = page
                    pageThumbView.clearForReuse()
                    
                    //Max thumb size
                    let size: CGSize = CGSizeMake(THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT)
                    
                    //Get the thumb for the page
                    let request: PDFKThumbRequest = PDFKThumbRequest(thumbView: pageThumbView, fileURL: document.fileURL, password: document.password, guid: document.guid, pageNumber: UInt(page), ofSize: size)
                    
                    if let image: UIImage = PDFKThumbCache.sharedInstance().thumbWithThumbRequest(request, hasPriority: true) {
                        pageThumbView.showImage(image)
                    }
                }
            }
        }
    }
    
    override func layoutSubviews() {
        //Update the container view width from the current bounds
        let containerWidth: CGFloat = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) ? UIScreen.mainScreen().bounds.size.width : UIScreen.mainScreen().bounds.size.height
        containerView.frame = CGRectMake(PAGE_NUMBER_SPACE, 0, containerWidth - (PAGE_NUMBER_SPACE * 2), 44.0)
        
        super.layoutSubviews()
        
        //Calculate the number of thumbs to display
        var controlRect = CGRectMake(PAGE_NUMBER_SPACE, 0, containerWidth - (PAGE_NUMBER_SPACE * 2), 44.0)
        let thumbWidth: CGFloat = THUMB_SMALL_WIDTH + THUMB_SMALL_GAP
        var thumbs: UInt = UInt(controlRect.size.width / thumbWidth)
        let pages: UInt = document.pageCount
        
        //Constrain to the total number of pages
        if thumbs > document.pageCount {
            thumbs = pages
        }
        
        //Update the control width
        let controlWidth: CGFloat = (CGFloat(thumbs) * thumbWidth) - THUMB_SMALL_GAP
        controlRect.size.width = controlWidth
        
        let widthDelta: CGFloat = containerView.bounds.size.width - controlWidth
        let x: CGFloat = widthDelta / 2.0
        trackControl.frame = controlRect
        
        //Create the page thumb view when needed
        if pageThumbView == nil {
            let heightDelta: CGFloat = controlRect.size.height - THUMB_LARGE_HEIGHT
            
            //Thumb X, Y
            let thumbX: CGFloat = 0
            let thumbY: CGFloat = heightDelta / 2.0
            
            let thumbRect = CGRectMake(thumbX, thumbY, THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT)
            
            //Create the thumb view
            pageThumbView = PDFKPageScrubberThumbView(frame: thumbRect)
            //Set the Z position so that is sits on top of the small thumbs
            pageThumbView!.layer.zPosition = 1.0
            //Add to the track control
            trackControl.addSubview(pageThumbView!)
        }
        
        //Update the page thumb view
        updatePageThumbView(document.currentPage)
        
        //Page stride
        let strideThumbs: UInt = thumbs - 1 > 1 ? thumbs - 1 : 1
        let stride: CGFloat = CGFloat(pages) / CGFloat(strideThumbs)
        let heightDelta: CGFloat = controlRect.size.height - THUMB_SMALL_HEIGHT
        
        //Initial X, Y
        let thumbY: Int = Int(heightDelta / 2.0)
        let thumbX: Int = 0
        
        let thumbRect: CGRect = CGRectMake(CGFloat(thumbX), CGFloat(thumbY), THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT)
        
        //Iterate through the needed thumbs
        var thumbsToHide: [Int: PDFKPageScrubberThumbView] = [:]
        for thumb in 0 ..< thumbs {
            //Page 
            var page: Int = (Int(stride) * thumb) + 1
            if page > pages {
                page = pages
            }
            
            if let smallThumbView = miniThumbViews[page] {
                //Reuse the existing small thumb view for the page
                smallThumbView.hidden = false
                thumbsToHide.removeValueForKey(page)
                
                if !CGRectEqualToRect(smallThumbView.frame, thumbRect) {
                    smallThumbView.frame = thumbRect
                }
            } else {
                //We need to create a new small thumb view for the page number
                //Max thumb size
                let size: CGSize = CGSizeMake(THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT)
                
                let smallThumbView = PDFKPageScrubberThumbView(frame: thumbRect, small: true)
                let request: PDFKThumbRequest = PDFKThumbRequest(thumbView: smallThumbView, fileURL: document.fileURL, password: document.password, guid: document.guid, pageNumber: page, ofSize: size)
                
                if let image = PDFKThumbCache.sharedInstance().thumbWithThumbRequest(request, hasPriority: false) {
                    smallThumbView.imageView.image = image
                }
                
                trackControl.addSubview(smallThumbView)
                miniThumbViews[page] = smallThumbView
            }
            
            //Next thumb x position
            thumbRect.origin.x += thumbWidth
        }
        
        //Hide unused thumbs
        for (page, thumb) in thumbsToHide {
            thumb.hidden = true
        }
    }
    
    private func updatePagebarViews() {
        //Update views to corespond to current page.
        updatePageNumberText(document.currentPage)
        updatePageThumbView(document.currentPage)
    }
    
    private func updatePageNumberText(page: Int) {
        //If the page number has changed
        if page != pageNumberLabel.tag {
            pageNumberLabel.text = "\(page) of \(document.pageCount)"
            pageNumberLabel.tag = page
        }
    }
    
    //------------------------------------------
    /// @name Track Control
    //------------------------------------------
    
    private func trackTimerFired(timer: NSTimer) {
        //Cleanup the timer
        trackTimer?.invalidate()
        trackTimer = nil
        
        //Enable track control user interaction
        trackControl.userInteractionEnabled = true
    }
    
    private func restartTrackTimer() {
        //Invalidate and release the previous timer
        if trackTimer != nil {
            trackTimer?.invalidate()
            trackTimer = nil
        }
        
        trackTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "trackTimerFired:", userInfo: nil, repeats: false)
    }
    
    private func startEnableTimer() {
        //Invalidate and release the previous timer
        if enableTimer != nil {
            enableTimer?.invalidate()
            enableTimer = nil
        }
        
        enableTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "enableTimerFired:", userInfo: nil, repeats: false)
    }
    
    private func trackViewPageNumber(trackView: PDFKPageScrubberTrackControl) -> Int {
        let controlWidth: CGFloat = trackView.bounds.size.width
        let stride: CGFloat = controlWidth / CGFloat(document.pageCount)
        
        //Get the page number
        let page: Int = Int(trackView.value / stride)
        
        return page + 1
    }
    
    private func trackViewTouchDown(trackView: PDFKPageScrubberTrackControl) {
        let page = trackViewPageNumber(trackView)
        
        if page != document.currentPage {
            //Update
            updatePageNumberText(page)
            updatePageThumbView(page)
            //Start tracking
            restartTrackTimer()
        }
        //Start tracking
        trackView.tag = page
    }
    
    private func trackViewValueChanged(trackView: PDFKPageScrubberTrackControl) {
        
        if page != document.currentPage {
            //Update
            updatePageNumberText(page)
            updatePageThumbView(page)
            //Update the page tracking tag
            trackView.tag = page
            //Start tracking
            restartTrackTimer()
        }
    }
    
    private func trackViewTouchUp(trackView: PDFKPageScrubberTrackControl) {
        //Finish tracking
        trackTimer?.invalidate()
        trackTimer = nil
        
        //Only if the page number has changed
        if trackView.tag != document.currentPage {
            //Disable track control interaction while the next page is loaded.
            trackView.userInteractionEnabled = false
            //Goto document page
            if let scrubberDelegate = scrubberDelegate {
                scrubberDelegate.scrubber(self, selectedPage: trackView.tag)
            }
            //Start track control enable timer
            startEnableTimer()
        }
        
        //Reset page tracking
        trackView.tag = 0
    }
}

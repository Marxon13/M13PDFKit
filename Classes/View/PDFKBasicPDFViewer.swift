//
//  PDFKBasicPDFViewer.swift
//  M13PDFKit
//
//  Created by Aleksandar Simovic on 4/6/15.
//  Copyright (c) 2015 BrandonMcQuilkin. All rights reserved.
//

import Foundation
import UIKit

public typealias PDFKBasicPDFViewerPageChangeBlock = (page: UInt) -> Void

public class PDFKBasicPDFViewerSwift: UIViewController, UIToolbarDelegate, UIDocumentInteractionControllerDelegate, PDFKPageScrubberDelegate, UIGestureRecognizerDelegate, PDFKBasicPDFViewerThumbsCollectionViewDelegate, PDFKBasicPDFViewerSinglePageCollectionViewDelegate {
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    /**
    The document that is being displayed in the viewer.
    */
    public var document: PDFKDocument?
    
    //------------------------------------------
    /// @name Callbacks
    //------------------------------------------
    
    /**
    The block that is run when the currently displayed page is changed.
    */
    public var pageChangeBlock: PDFKBasicPDFViewerPageChangeBlock?
    
    //------------------------------------------
    /// @name Features
    //------------------------------------------
    
    /**
    Wether or not to allow bookmarking of pages.
    */
    public var enableBookmarks: Bool = false
    
    /**
    Wether or not to enable sharing of the PDF.
    */
    public var enableSharing: Bool = false
    
    /**
    Wether or not to enable printing of the PDF.
    */
    public var enablePrinting: Bool = false
    
    /**
    Wether or not to allow opening of the file in other apps.
    */
    public var enableOpening: Bool = false
    
    /**
    Wether or not to show the thumbnail slider at the bottom of the screen.
    */
    public var enableThumbnailSlider: Bool = false
    
    /**
    Wether or not to allow zooming out of a page to show multiple pages.
    */
    public var enablePreview: Bool = false
    
    /**
    If false, a done button is added to the toolbar.
    */
    public var standalone: Bool = false
    
    
    //------------------------------------------
    /// @name Internal Properties
    //------------------------------------------
    
    /**
    The toolbar displaied at the top of the screen.
    */
    private var navigationToolbar: UIToolbar?
    
    /**
    The slider at the bottom of the screen to show the thumbnails.
    */
    private var thumbnailSlider: UIToolbar?
    
    /**
    The popover controller to share the document on the iPad.
    */
    private var activityPopoverController: UIPopoverController?
    
    /**
    The share button.
    */
    private var shareItem: UIBarButtonItem?
    
    /**
    The item that notes wether or not the page is bookmarked.
    */
    private var bookmarkItem: UIBarButtonItem?
    
    /**
    The page scrubber at the bottom of the view.
    */
    private var pageScrubber: PDFKPageScrubber?
    
    /**
    The collection view of single pages to display.
    */
    private var pageCollectionView: PDFKBasicPDFViewerSinglePageCollectionView?
    
    /**
    Wether or not the view is showing a single page.
    */
    private var showingSinglePage: Bool = false
    
    /**
    The collection view that displays all the thumbs.
    */
    private var thumbsCollectionView: PDFKBasicPDFViewerThumbsCollectionView?
    
    /**
    Wether or not the thumbs collection view is showing thumbs.
    */
    private var showingBookmarks: Bool = false
    /**
    True once view did load called.
    */
    private var loadedView: Bool = false
    
    /**
    The gesture recognizer that detects single taps.
    */
    private var singleTapGestureRecognizer: UITapGestureRecognizer?
    
    /**
    The gesture recognizer that detects double taps.
    */
    private var doubleTapGestureRecognizer: UITapGestureRecognizer?
    
    /**
    The gesture recognizer that detects two finger double taps.
    */
    private var doubleTwoFingerTapGestureRecognizer: UITapGestureRecognizer?
    
    //------------------------------------------
    /// @name Initalization and Loading
    //------------------------------------------
    
    /**
    Initalize the PDF viewer with a PDF Document.
    
    @param document The document to show.
    
    @return A pdf viewer with a document.
    */
    public init(document: PDFKDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }
    
    /**
    Initalize the PDF viewer without a PDF Document. One will have to use `loadDocument()` to load a document into the viewer before showing.
    
    @note Actual support for this would be nice.
    
    @param aDecoder The decoder that contains the in.
    
    @return A pdf viewer without a document.
    */
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
    This method is to be used to load a document if this view controller will be displaied via segue.
    @note If the reader already has a document, a new document will not be set.
    
    @param document The document to load.
    */
    public func loadDocument(document: PDFKDocument) -> Void {
        
        //If we already have a document, and have loaded it, return
        if !loadedView {
            self.document = document
            return
        }
        
        //Set the document
        self.document = document
        
        //Set the background color
        self.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        //----------------------
        //Create the thumbs view
        //----------------------
        
        self.thumbsCollectionView = PDFKBasicPDFViewerThumbsCollectionView(frame: self.view.bounds, andDocument: document)
        self.thumbsCollectionView!.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(self.thumbsCollectionView!)
        self.thumbsCollectionView!.pageDelegate = self
        
        //Set the constraints on the collection view.
        var thumbsHorizontalConstraints =
        NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|[collectionView]|",
            options: NSLayoutFormatOptions.AlignAllBaseline,
            metrics: nil,
            views: ["superview": self.view, "collectionView": self.thumbsCollectionView!])
        
        var thumbsVerticalConstraints =
        NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[collectionView]|",
            options: NSLayoutFormatOptions.AlignAllLeft,
            metrics: nil,
            views: ["superview": self.view, "collectionView": self.thumbsCollectionView!])
        
        self.view.addConstraints(thumbsHorizontalConstraints)
        self.view.addConstraints(thumbsVerticalConstraints)
        
        //Set the content insets, Need to account for top bar, navigation toolbar, and bottom bar.
        self.thumbsCollectionView!.hidden = true
        self.showingSinglePage = true
        
        //---------------------------
        //Create the single page view
        //---------------------------
        
        self.pageCollectionView = PDFKBasicPDFViewerSinglePageCollectionView(frame: self.view.bounds, andDocument: self.document)
        self.pageCollectionView!.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.pageCollectionView!.singlePageDelegate = self
        self.view.addSubview(self.pageCollectionView!)
        
        // Set its constraints
        var pageConstraints: NSMutableArray = NSMutableArray(
            array: NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[collectionView]|",
                options: NSLayoutFormatOptions.AlignAllBaseline,
                metrics: nil,
                views: ["superview": self.view, "collectionView": self.pageCollectionView!]
            )
        )
        pageConstraints.addObjectsFromArray(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|[collectionView]|",
                options:NSLayoutFormatOptions.AlignAllLeft,
                metrics:nil,
                views: ["superview": self.view, "collectionView": self.pageCollectionView!]
            )
        )
        self.view.addConstraints(pageConstraints as [AnyObject])
        
        //---------------------------
        //Create the navigation bar
        //---------------------------
        
        self.navigationToolbar = UIToolbar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44.0))
        self.navigationToolbar!.delegate = self
        //Set this to no, cant have autoresizing masks and layout constraints at the same time.
        self.navigationToolbar!.setTranslatesAutoresizingMaskIntoConstraints(false)
        //Add to the view
        self.view.addSubview(self.navigationToolbar!)
        // Set its constraints.
        var navigationToolbarConstraints: NSMutableArray = NSMutableArray(
            array: NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[toolbar]|",
                options: NSLayoutFormatOptions.AlignAllBaseline,
                metrics: nil,
                views: ["superview": self.view, "toolbar": self.navigationToolbar!]
            )
        )
        navigationToolbarConstraints.addObjectsFromArray(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:[topLayout]-0-[toolbar(44)]",
                options: NSLayoutFormatOptions.AlignAllLeft,
                metrics: nil,
                views: ["toolbar": self.navigationToolbar!, "topLayout": self.topLayoutGuide]
            )
        )
        self.view.addConstraints(navigationToolbarConstraints as [AnyObject])
        //Finish setup
        self.navigationToolbar!.sizeToFit()
        resetNavigationToolbar()
        
        //---------------------------
        //Create the scrubber
        //---------------------------
        
        self.pageScrubber = PDFKPageScrubber(
            frame: CGRectMake(0, self.view.frame.size.height - self.bottomLayoutGuide.length, self.view.frame.size.width, 44.0),
            document: self.document)
        
        self.pageScrubber!.scrubberDelegate = self
        self.pageScrubber!.delegate = self
        //Set this to no, cant have autoresizing masks and layout constraints at the same time.
        self.pageScrubber!.setTranslatesAutoresizingMaskIntoConstraints(false)
        //Add to the view
        self.view.addSubview(pageScrubber!)
        //Create the constraints
        var pageScrubberConstraints: NSMutableArray = NSMutableArray(
            array: NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[scrubber]|",
                options: NSLayoutFormatOptions.AlignAllBaseline,
                metrics: nil,
                views: ["superview": self.view, "scrubber": self.pageScrubber!]
            )
        )
        
        pageScrubberConstraints.addObjectsFromArray(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:[scrubber(44)]-0-[bottomLayout]",
                options: NSLayoutFormatOptions.AlignAllLeft,
                metrics: nil,
                views: ["scrubber": self.pageScrubber!, "bottomLayout": self.bottomLayoutGuide]
            )
        )
        self.view.addConstraints(pageScrubberConstraints as [AnyObject])
        //Finish
        self.pageScrubber!.sizeToFit()
        
        //---------------------------
        //Add the tap gesture recognizers
        //---------------------------
        
        // Next page, previous page, handle link, handle toggle toolbars
        self.singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleSingleTap:"))
        self.singleTapGestureRecognizer!.numberOfTapsRequired = 1
        self.singleTapGestureRecognizer!.numberOfTouchesRequired = 1
        self.singleTapGestureRecognizer!.cancelsTouchesInView = true
        self.singleTapGestureRecognizer!.delegate = self
        self.view.addGestureRecognizer(self.singleTapGestureRecognizer!)
        
        // Handle zoom in
        self.doubleTapGestureRecognizer = UITapGestureRecognizer(target: self,
            action: Selector("handleDoubleTap:"))
        self.doubleTapGestureRecognizer!.numberOfTouchesRequired = 1
        self.doubleTapGestureRecognizer!.numberOfTapsRequired = 2
        self.doubleTapGestureRecognizer!.delegate = self
        self.view.addGestureRecognizer(self.doubleTapGestureRecognizer!)
        
        self.singleTapGestureRecognizer!.requireGestureRecognizerToFail(self.doubleTapGestureRecognizer!)
        
        // Handle zoom out
        self.doubleTwoFingerTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: Selector("handleDoubleTap:"))
        self.doubleTwoFingerTapGestureRecognizer!.numberOfTouchesRequired = 2
        self.doubleTwoFingerTapGestureRecognizer!.numberOfTapsRequired = 2
        self.doubleTwoFingerTapGestureRecognizer!.delegate = self
        self.view.addGestureRecognizer(self.doubleTwoFingerTapGestureRecognizer!)
        
    }
    
    override public func viewDidLoad() -> Void {
        super.viewDidLoad()
        //The view has been loaded, load the document if one exists.
        loadedView = true
        if let document = self.document {
            self.loadDocument(document)
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Save the document if one exists
        document?.saveReaderDocument()
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resource that can be recreated
    }
    
    /** Layout **/
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Doing this since querying the layout guides a second time returns 0.
        var topLayoutGuideLength: CGFloat = self.topLayoutGuide.length
        var bottomLayoutGuideLength: CGFloat = self.bottomLayoutGuide.length
        
        //Content insets
        self.pageCollectionView?.contentInset = UIEdgeInsetsMake(topLayoutGuideLength, 0, bottomLayoutGuideLength, 0)
        self.thumbsCollectionView?.contentInset = UIEdgeInsetsMake(topLayoutGuideLength + 44.0, 0, bottomLayoutGuideLength, 0)
        
        self.pageCollectionView?.collectionViewLayout.invalidateLayout()
        self.thumbsCollectionView?.collectionViewLayout.invalidateLayout()

        self.view.layoutSubviews()
    }
    
    public func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        //Define the position for each of the toolbars.
        if bar === self.navigationToolbar {
            return UIBarPosition.Top
        }
        if bar === self.pageScrubber {
            return UIBarPosition.Bottom
        }
        return UIBarPosition.Bottom
    }
    
    override public func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) -> Void {
        //Invalidate the layouts of the collection views on rotation, and animate the rotation.
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        self.thumbsCollectionView?.collectionViewLayout.invalidateLayout()
        self.pageCollectionView?.collectionViewLayout.invalidateLayout()
        
        if let document = self.document {
            self.pageCollectionView?.displayPage(document.currentPage, animated: false)
        }
    }
    
    override public func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) -> Void {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
    }
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransition({ (context) -> Void in
            self.thumbsCollectionView?.collectionViewLayout.invalidateLayout()
            self.pageCollectionView?.collectionViewLayout.invalidateLayout()
            if let document = self.document {
                self.pageCollectionView?.displayPage(document.currentPage, animated: false)
            }
        }, completion: { (context) -> Void in
            
        })
    }
    
    /** Navigation Bar **/
    
    func resetNavigationToolbar() -> Void {
        var buttonsArray: NSMutableArray = NSMutableArray()
        
        // Set controls for a single page.
        if self.showingSinglePage {
            
            // Done Button
            if !self.standalone {
                buttonsArray.addObject(
                    UIBarButtonItem(
                        barButtonSystemItem: UIBarButtonSystemItem.Done,
                        target: self,
                        action: Selector("dismiss")
                    )
                )
                buttonsArray.addObject(
                    UIBarButtonItem(
                        barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace,
                        target: nil,
                        action: nil
                    )
                )
            }
            
            // Add space if necessary
            if buttonsArray.count > 0 {
                var space: UIBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.FixedSpace,
                    target: nil,
                    action: nil
                )
                space.width = 10.0
                buttonsArray.addObject(space)
            }
            
            // Add list
            var listItem: UIBarButtonItem = UIBarButtonItem(
                image: UIImage(named: "Thumbs"),
                landscapeImagePhone: UIImage(named: "Thumbs"),
                style: UIBarButtonItemStyle.Plain,
                target: self,
                action: Selector("list")
            )
            buttonsArray.addObject(listItem)
            
            // Sharing Button
            if (self.enableSharing || self.enablePrinting || self.enableOpening) {
                var space: UIBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.FixedSpace,
                    target: nil,
                    action: nil
                )
                space.width = 10.0
                buttonsArray.addObject(space)
                self.shareItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.Action,
                    target: self,
                    action: Selector("send")
                )
                buttonsArray.addObject(self.shareItem!)
            }
            
            // Flexible space
            buttonsArray.addObject(
                UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace,
                    target:nil,
                    action:nil
                )
            )
            
            // Bookmark Button
            if self.enableBookmarks {
                // Add space
                var space = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.FixedSpace,
                    target: nil,
                    action:nil
                )
                space.width = 10.0
                buttonsArray.addObject(space)
                
                // Add bookmarks
                // Change image based on wether or not the page is bookmarked
                if let document = self.document {
                    if (!document.bookmarks.containsIndex(Int(document.currentPage))) {
                        self.bookmarkItem = UIBarButtonItem(
                            image: UIImage(named: "Bookmark"),
                            style: UIBarButtonItemStyle.Plain,
                            target: self,
                            action: Selector("bookmark")
                        )
                    } else {
                        self.bookmarkItem = UIBarButtonItem(
                            image: UIImage(named: "Bookmarked"),
                            style: UIBarButtonItemStyle.Plain,
                            target: self,
                            action: Selector("bookmark")
                        )
                    }
                    buttonsArray.addObject(self.bookmarkItem!)
                }
                
                
            }
        } else {
            
            // Set controls for thumbs
            // Done Button
            if !self.standalone {
                buttonsArray.addObject(
                    UIBarButtonItem(
                        barButtonSystemItem: UIBarButtonSystemItem.Done,
                        target: self,
                        action: Selector("dismiss")
                    )
                )
                buttonsArray.addObject(
                    UIBarButtonItem(
                        barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace,
                        target: nil,
                        action:nil
                    )
                )
            }
            
            // Add space if necessary
            if buttonsArray.count > 0 {
                var space: UIBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.FixedSpace,
                    target: nil,
                    action: nil
                )
                space.width = 10.0
                buttonsArray.addObject(space)
            }
            
            // Go back
            var listItem: UIBarButtonItem = UIBarButtonItem(
                title: "Resume",
                style: UIBarButtonItemStyle.Plain,
                target: self,
                action: Selector("list")
            )
            buttonsArray.addObject(listItem)
            
            // Flexible space
            buttonsArray.addObject(
                UIBarButtonItem(
                    barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace,
                    target:nil,
                    action:nil
                )
            )
            
            // Bookmarks
            let images = [UIImage(named: "Thumbs")!, UIImage(named: "Bookmark")!]
            var control: UISegmentedControl = UISegmentedControl(items: images)
            control.selectedSegmentIndex = !self.showingBookmarks ? 0 : 1
            control.sizeToFit()
            control.addTarget(
                self,
                action: Selector("toggleShowBookmarks:"),
                forControlEvents: UIControlEvents.ValueChanged)
            var bookmarkItem: UIBarButtonItem = UIBarButtonItem(customView: control)
            buttonsArray.addObject(bookmarkItem)
        }
        
        self.navigationToolbar?.setItems(buttonsArray as [AnyObject], animated: true)
    }
    
    /** Actions **/
    
    func dismiss() -> Void {
        if ((self.presentingViewController) != nil) {
            self.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    func send() -> Void {
        var activityViewController: UIActivityViewController?
        var openInAppActivity: TTOpenInAppActivity?
        
        if enableOpening {
            if let document = self.document {
                openInAppActivity = TTOpenInAppActivity(view: self.view, andBarButtonItem: shareItem)
                activityViewController = UIActivityViewController(activityItems: [document.fileURL], applicationActivities: [openInAppActivity!])
            }
        } else {
            if let document = self.document {
                activityViewController = UIActivityViewController(activityItems: [document.fileURL], applicationActivities: nil)
            }
        }
        
        if let activityViewController = activityViewController {
            if !enablePrinting {
                activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeCopyToPasteboard]
            }
            
            if !enableSharing {
                var array: NSMutableArray = [UIActivityTypeAirDrop, UIActivityTypeCopyToPasteboard, UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTencentWeibo, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo] as NSMutableArray
                if (activityViewController.excludedActivityTypes!.count == 1){
                    array.addObjectsFromArray(activityViewController.excludedActivityTypes!)
                }
                activityViewController.excludedActivityTypes = array as [AnyObject]
            }
            
            if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
                // Store reference to superview (UIActionSheet) to allow dismissal
                openInAppActivity?.superViewController = activityViewController
                // Show UIActivityViewController
                self.presentViewController(activityViewController, animated:true, completion:nil)
            } else {
                // Create pop up
                self.activityPopoverController = UIPopoverController(contentViewController: activityViewController)
                // Store reference to superview (UIPopoverController) to allow dismissal
                openInAppActivity?.superViewController = self.activityPopoverController
                // Show UIActivityViewController in popup
                self.activityPopoverController!.presentPopoverFromBarButtonItem(
                    self.shareItem!,
                    permittedArrowDirections: UIPopoverArrowDirection.Any,
                    animated: true
                )
            }
        }
    }
    
    func bookmark() -> Void {
        if let document = document {
            let currentPage: Int = Int(document.currentPage)
            if (document.bookmarks.containsIndex(currentPage)) {
                document.bookmarks.removeIndex(currentPage)
            } else {
                document.bookmarks.addIndex(currentPage)
            }
            resetNavigationToolbar()
        }
    }
    
    func list() -> Void {
        self.toggleSinglePageView()
    }
    
    func toggleShowBookmarks (sender: UISegmentedControl) -> Void { // TODO: check the segmented control
        var control: UISegmentedControl = sender
        let isSelectedSegmentedIndex: Bool = (control.selectedSegmentIndex == 0)
        thumbsCollectionView?.showBookmarkedPages(isSelectedSegmentedIndex)
    }
    
    /** Page Control **/
    
    public func thumbCollectionView(thumbsCollectionView: PDFKBasicPDFViewerThumbsCollectionView, didSelectPage page: UInt) -> Void {
        if let document = document {
            self.pageCollectionView?.displayPage(document.currentPage, animated:true)
            document.currentPage = UInt(page)
            self.pageScrubber?.updateScrubber()
            self.toggleSinglePageView()
        }
    }
    
    public func scrubber(pageScrubber: PDFKPageScrubber, selectedPage page: Int) -> Void {
        if let document = self.document {
            document.currentPage = UInt(page)
            self.pageCollectionView?.displayPage(document.currentPage, animated:false)
            self.resetNavigationToolbar()
        }
    }
    
    public func singlePageCollectionView(collectionView: PDFKBasicPDFViewerSinglePageCollectionView, didDisplayPage page:UInt) -> Void {
        self.document?.currentPage = UInt(page)
        self.pageScrubber?.updateScrubber()
        self.resetNavigationToolbar()
        
        if let pageChangeBlock = self.pageChangeBlock {
            pageChangeBlock(page)
        }
    }
    
    //------------------------------------------
    /// @name Controls
    //------------------------------------------
    
    /**
    Have the PDF viewer display the next page.
    */
    public func nextPage() -> Void {
        if let document = self.document {
            document.currentPage += 1
            pageScrubber?.updateScrubber()
            pageCollectionView?.displayPage(document.currentPage, animated:true)
            self.resetNavigationToolbar()
        }
    }
    
    /**
    Have the PDF viewer display the previous page.
    */
    public func previousPage() -> Void {
        if let document = self.document {
            document.currentPage -= 1
            pageScrubber?.updateScrubber()
            pageCollectionView?.displayPage(document.currentPage, animated:true)
            self.resetNavigationToolbar()
        }
    }
    
    /**
    Have the PDF viewer display the given page.
    
    @param page The number of the page to display.
    */
    public func displayPage(page: UInt) -> Void {
        if let document = self.document {
            document.currentPage = page
            pageScrubber?.updateScrubber()
            pageCollectionView?.displayPage(document.currentPage, animated:true)
            self.resetNavigationToolbar()
        }
    }
    
    
    /** Gestures **/
    
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if !showingSinglePage {
            return false;
        }
        
        return true;
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        var location: CGPoint = touch.locationInView(self.view)
        
        //We want to cancel the toggle gesture if we are on the toolbars while they are visible
        if let navigationToolbar = self.navigationToolbar, let pageScrubber = self.pageScrubber {
            if navigationToolbar.hidden == false {
                if (CGRectContainsPoint(navigationToolbar.frame, location) || CGRectContainsPoint(pageScrubber.frame, location)) {
                    return false
                }
            }
        }
        
        return true
    }
    
    func handleSingleTap(gestureRecognizer: UITapGestureRecognizer) -> Void {
        //Check to see if the document was clicked.
        if (gestureRecognizer.state == UIGestureRecognizerState.Ended && showingSinglePage) {
            if (gestureRecognizer.numberOfTapsRequired == 1) {
                //Check what side the touch is on
                var touch: CGPoint = gestureRecognizer.locationInView(self.view)
                
                //Left side
                if (CGRectContainsPoint(CGRectMake(0, 0, self.view.frame.size.width * 0.33, self.view.frame.size.height), touch)) {
                    self.previousPage()
                    
                } else if (CGRectContainsPoint(CGRectMake(self.view.frame.size.width * 0.33, 0, self.view.frame.size.width * 0.33, self.view.frame.size.height), touch)) {
                    //Center
                    self.toggleToolbars()
                    
                } else {
                    //Right
                    self.nextPage()
                }
            }
        }
        
    }
    
    func handleDoubleTap(gestureRecognizer: UITapGestureRecognizer) -> Void {
        if (gestureRecognizer.state == UIGestureRecognizerState.Ended) {
            if (gestureRecognizer.numberOfTouchesRequired == 1) {
                //Zoom in
                if let cell: PDFKBasicPDFViewerSinglePageCollectionViewCell = self.pageCollectionView?.visibleCells()[0] as? PDFKBasicPDFViewerSinglePageCollectionViewCell {
                    cell.pageContentView.zoomIncrement()
                }
            } else {
                //Zoom out
                if let cell: PDFKBasicPDFViewerSinglePageCollectionViewCell = self.pageCollectionView?.visibleCells()[0] as? PDFKBasicPDFViewerSinglePageCollectionViewCell {
                    cell.pageContentView.zoomDecrement()
                }
            }
        }
    }
    
    /** Views **/
    
    func toggleToolbars() -> Void {
        
        if (self.showingSinglePage) {
            if (self.navigationToolbar?.hidden == true){
                //Show toolbars
                self.navigationToolbar?.hidden = false
                self.pageScrubber?.hidden = false
                UIView.animateWithDuration(
                    Double(0.3),
                    animations: {
                        if (self.navigationToolbar?.alpha == 0.0) {
                            self.navigationToolbar?.alpha = 1.0
                        }
                        if (self.pageScrubber?.alpha == 0.0) {
                            self.pageScrubber?.alpha = 1.0
                        }
                    }
                )
            } else {
                //Hide toolbars
                UIView.animateWithDuration(
                    Double(0.3),
                    animations: {
                        if (self.navigationToolbar?.alpha == 1.0) {
                            self.navigationToolbar?.alpha = 0.0
                        }
                        if (self.pageScrubber?.alpha == 1.0) {
                            self.pageScrubber?.alpha = 0.0
                        }
                    },
                    completion: {(finished: Bool) -> Void in
                        if finished {
                            self.navigationToolbar?.hidden = true
                            self.pageScrubber?.hidden = true
                        }
                    }
                )
            }
        }
    }
    
    func toggleSinglePageView() -> Void {
        if showingSinglePage {
            //Show the thumbs view.
            showingSinglePage = false
            resetNavigationToolbar()
            thumbsCollectionView?.showBookmarkedPages(false)
            thumbsCollectionView?.reloadData()
            
            //Hide the slider if showing, show the nav bar if not showing
            navigationToolbar?.hidden = false
            thumbsCollectionView?.hidden = false
            
            UIView.animateWithDuration(
                Double(0.3),
                animations: {
                    if (self.navigationToolbar?.alpha == 0.0) {
                        self.navigationToolbar?.alpha = 1.0
                    }
                    if (self.pageScrubber?.alpha == 1.0) {
                        self.pageScrubber?.alpha = 0.0
                    }
                    if (self.pageCollectionView?.alpha == 1.0) {
                        self.pageCollectionView?.alpha = 0.0
                    }
                },
                completion: {(finished: Bool) -> Void in
                    self.pageScrubber?.hidden = true
                    self.pageCollectionView?.hidden = true
                }
            )
        } else {
            showingSinglePage = true
            self.resetNavigationToolbar()
            self.pageScrubber?.hidden = false
            self.pageCollectionView?.hidden = false
            UIView.animateWithDuration(
                Double(0.3),
                animations: {
                    if (self.pageScrubber?.alpha == 0.0) {
                        self.pageScrubber?.alpha = 1.0
                    }
                    if (self.pageCollectionView?.alpha == 0.0) {
                        self.pageCollectionView?.alpha = 1.0
                    }
                },
                completion: {(finished: Bool) -> Void in
                    //Hide so we don't have to render.
                    self.thumbsCollectionView?.hidden = true
                }
            )
        }
    }
    
}
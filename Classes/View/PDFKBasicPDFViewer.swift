//
//  PDFKBasicPDFViewer.swift
//  M13PDFKit
//
//  Created by Aleksandar Simovic on 4/6/15.
//  Copyright (c) 2015 BrandonMcQuilkin. All rights reserved.
//

import Foundation
import UIKit

class PDFKBasicPDFViewerSwift: UIViewController, UIToolbarDelegate, UIDocumentInteractionControllerDelegate, PDFKPageScrubberDelegate, UIGestureRecognizerDelegate, PDFKBasicPDFViewerThumbsCollectionViewDelegate, PDFKBasicPDFViewerSinglePageCollectionViewDelegate {
  
  var document: PDFKDocument!
  
  var enableBookmarks: Bool?
  var enableSharing: Bool?
  var enablePrinting: Bool?
  var enableOpening: Bool?
  var enableThumbnailSlider: Bool?
  var enablePreview: Bool?
  var standalone: Bool?
  
  var navigationToolbar: UIToolbar!
  var thumbnailSlider: UIToolbar!
  var activityPopoverController: UIPopoverController!
  var shareItem: UIBarButtonItem!
  var bookmarkItem: UIBarButtonItem!
  var pageScrubber: PDFKPageScrubber!
  var pageCollectionView: PDFKBasicPDFViewerSinglePageCollectionView!
  var showingSinglePage: Bool?
  var thumbsCollectionView: PDFKBasicPDFViewerThumbsCollectionView!
  var showingBookmarks: Bool?
  var loadedView: Bool?
  
  var singleTapGestureRecognizer: UITapGestureRecognizer!
  var doubleTapGestureRecognizer: UITapGestureRecognizer!
  
  
  /** Initialization and Loading **/
  
  override init(){
    super.init()
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nil, bundle: nil)
  }
  
  init(document: PDFKDocument) {
    self.document = document
    super.init()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init()
  }
  
  func loadDocument(document: PDFKDocument) -> Void {
    
    if !(loadedView != nil) {
      //Don't load yet. Need view did load to be called first.
      self.document = document
      return
    }
    
    self.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
    
    //Defaults
    self.enableBookmarks = true
    self.enableSharing = true
    self.enablePrinting = true
    self.enableOpening = true
    self.enableThumbnailSlider = true
    self.enablePreview = true
    self.standalone = true
    self.document = document
    
    
    /** Create the thumbs view **/
    
    self.thumbsCollectionView = PDFKBasicPDFViewerThumbsCollectionView(frame: self.view.bounds, andDocument: document)
    self.thumbsCollectionView.setTranslatesAutoresizingMaskIntoConstraints(false)
    self.view.addSubview(self.thumbsCollectionView)
    self.thumbsCollectionView.pageDelegate = self
    
    //Set the constraints on the collection view.
    var thumbsConstraints: NSMutableArray = NSMutableArray(
      array: NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[collectionView]|",
        options: NSLayoutFormatOptions.AlignAllBaseline,
        metrics:nil,
        views: ["superview": self.view, "collectionView": self.thumbsCollectionView])
    )
    
    thumbsConstraints.addObjectsFromArray(
      NSLayoutConstraint.constraintsWithVisualFormat(
        "V:|[collectionView]|",
        options: NSLayoutFormatOptions.AlignAllLeft,
        metrics: nil,
        views: ["superview": self.view, "collectionView": self.thumbsCollectionView]
      )
    )
    self.view.addConstraints(thumbsConstraints)
    
    //Set the content insets, Need to account for top bar, navigation toolbar, and bottom bar.
    self.thumbsCollectionView.hidden = true
    self.showingSinglePage = true
    
    
    /** Create the single page view **/
    
    self.pageCollectionView = PDFKBasicPDFViewerSinglePageCollectionView(frame: self.view.bounds,andDocument: self.document)
    self.pageCollectionView.setTranslatesAutoresizingMaskIntoConstraints(false)
    self.pageCollectionView.singlePageDelegate = self
    self.view.addSubview(self.pageCollectionView)
    
    // Set its constraints
    var pageConstraints: NSMutableArray = NSMutableArray(
      array: NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[collectionView]|",
        options: NSLayoutFormatOptions.AlignAllBaseline,
        metrics: nil,
        views: ["superview": self.view, "collectionView": self.pageCollectionView]
      )
    )
    pageConstraints.addObjectsFromArray(
      NSLayoutConstraint.constraintsWithVisualFormat(
        "V:|[collectionView]|",
        options:NSLayoutFormatOptions.AlignAllLeft,
        metrics:nil,
        views: ["superview": self.view, "collectionView": self.pageCollectionView]
      )
    )
    self.view.addConstraints(pageConstraints)
    
    
    /** Create the navigation bar **/
    
    self.navigationToolbar = UIToolbar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44.0))
    self.navigationToolbar.delegate = self
    //Set this to no, cant have autoresizing masks and layout constraints at the same time.
    self.navigationToolbar.setTranslatesAutoresizingMaskIntoConstraints(false)
    //Add to the view
    self.view.addSubview(self.navigationToolbar)
    // Set its constraints.
    var navigationToolbarConstraints: NSMutableArray = NSMutableArray(
      array: NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[toolbar]|",
        options: NSLayoutFormatOptions.AlignAllBaseline,
        metrics: nil,
        views: ["superview": self.view, "toolbar": self.navigationToolbar]
      )
    )
    navigationToolbarConstraints.addObjectsFromArray(
      NSLayoutConstraint.constraintsWithVisualFormat(
        "V:[topLayout]-0-[toolbar(44)]",
        options: NSLayoutFormatOptions.AlignAllLeft,
        metrics: nil,
        views: ["toolbar": self.navigationToolbar, "topLayout": self.topLayoutGuide]
      )
    )
    self.view.addConstraints(navigationToolbarConstraints)
    //Finish setup
    self.navigationToolbar.sizeToFit()
    resetNavigationToolbar()
    
    
    /** Create the Scrubber **/
    
    self.pageScrubber = PDFKPageScrubber(
      frame: CGRectMake(0, self.view.frame.size.height - self.bottomLayoutGuide.length, self.view.frame.size.width, 44.0),
      document: self.document)
    
    self.pageScrubber.scrubberDelegate = self
    self.pageScrubber.delegate = self
    //Set this to no, cant have autoresizing masks and layout constraints at the same time.
    self.pageScrubber.setTranslatesAutoresizingMaskIntoConstraints(false)
    //Add to the view
    self.view.addSubview(pageScrubber)
    //Create the constraints
    var pageScrubberConstraints: NSMutableArray = NSMutableArray(
      array: NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[scrubber]|",
        options: NSLayoutFormatOptions.AlignAllBaseline,
        metrics: nil,
        views: ["superview": self.view, "scrubber": self.pageScrubber]
      )
    )
    
    pageScrubberConstraints.addObjectsFromArray(
      NSLayoutConstraint.constraintsWithVisualFormat(
        "V:[scrubber(44)]-0-[bottomLayout]",
        options: NSLayoutFormatOptions.AlignAllLeft,
        metrics: nil,
        views: ["scrubber": self.pageScrubber, "bottomLayout": self.bottomLayoutGuide]
      )
    )
    self.view.addConstraints(pageScrubberConstraints)
    //Finish
    self.pageScrubber.sizeToFit()
    
    
    /** Add the tap gesture recognizers **/
    
    // Next page, previous page, handle link, handle toggle toolbars
    self.singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleSingleTap:"))
    self.singleTapGestureRecognizer.numberOfTapsRequired = 1
    self.singleTapGestureRecognizer.numberOfTouchesRequired = 1
    self.singleTapGestureRecognizer.cancelsTouchesInView = true
    self.singleTapGestureRecognizer.delegate = self
    self.view.addGestureRecognizer(self.singleTapGestureRecognizer)
    
    // Handle zoom in
    self.doubleTapGestureRecognizer = UITapGestureRecognizer(target: self,
      action: Selector("handleDoubleTap:"))
    self.doubleTapGestureRecognizer.numberOfTouchesRequired = 1
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
    self.doubleTapGestureRecognizer.delegate = self
    self.view.addGestureRecognizer(self.doubleTapGestureRecognizer)
    
    self.singleTapGestureRecognizer.requireGestureRecognizerToFail(self.doubleTapGestureRecognizer)
    
    // Handle zoom out
    var doubleTwoFingerTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(
      target: self,
      action: Selector("handleDoubleTap:"))
    doubleTwoFingerTapGestureRecognizer.numberOfTouchesRequired = 2
    doubleTwoFingerTapGestureRecognizer.numberOfTapsRequired = 2
    doubleTwoFingerTapGestureRecognizer.delegate = self
    self.view.addGestureRecognizer(doubleTwoFingerTapGestureRecognizer)
    
  }
  
  override func viewDidLoad() -> Void {
    super.viewDidLoad()
    loadedView = true
    if (self.document != nil) {
      self.loadDocument(document)
    }
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Save the document
    document.saveReaderDocument()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resource that can be recreated
  }
  
  /** Layout **/
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    //Doing this since querying the layout guides a second time returns 0.
    var topLayoutGuideLength: CGFloat = self.topLayoutGuide.length
    var bottomLayoutGuideLength: CGFloat = self.bottomLayoutGuide.length
    
    //Content insets
    pageCollectionView.contentInset = UIEdgeInsetsMake(topLayoutGuideLength, 0, bottomLayoutGuideLength, 0)
    thumbsCollectionView.contentInset = UIEdgeInsetsMake(topLayoutGuideLength + 44.0, 0, bottomLayoutGuideLength, 0)
    
    pageCollectionView.collectionViewLayout.invalidateLayout()
    thumbsCollectionView.collectionViewLayout.invalidateLayout()
    
    self.view.layoutSubviews()
  }
  
  func positionForBar(bar: UIBarPositioning!) -> UIBarPosition {
    if bar === self.navigationToolbar {
      return UIBarPosition.Top
    }
    if bar === self.pageScrubber {
      return UIBarPosition.Bottom
    }
    return UIBarPosition.Bottom
  }
  
  override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) -> Void {
    //Invalidate the layouts of the collection views on rotation, and animate the rotation.
    super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
    
    thumbsCollectionView.collectionViewLayout.invalidateLayout()
    pageCollectionView.collectionViewLayout.invalidateLayout()
  }
  
  override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) -> Void {
    super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
  }
  
  
  /** Navigation Bar **/
  
  func resetNavigationToolbar() -> Void {
    var buttonsArray: NSMutableArray = NSMutableArray()
    
    // Set controls for a single page.
    if showingSinglePage! {
      
      // Done Button
      if !self.standalone! {
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
      if (self.enableSharing! || self.enablePrinting! || self.enableOpening!) {
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
        buttonsArray.addObject(self.shareItem)
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
      if self.enableBookmarks! {
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
        if (!self.document.bookmarks.containsIndex(Int(self.document.currentPage))) {
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
        
        buttonsArray.addObject(bookmarkItem)
      }
    } else {
      
      // Set controls for thumbs
      // Done Button
      if !self.standalone! {
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
      control.selectedSegmentIndex = !self.showingBookmarks! ? 0 : 1
      control.sizeToFit()
      control.addTarget(
        self,
        action: Selector("toggleShowBookmarks:"),
        forControlEvents: UIControlEvents.ValueChanged)
      var bookmarkItem: UIBarButtonItem = UIBarButtonItem(customView: control)
      buttonsArray.addObject(bookmarkItem)
    }
    
    self.navigationToolbar.setItems(buttonsArray, animated: true)
  }
  
  /** Actions **/
  
  func dismiss() -> Void {
    if ((self.presentingViewController) != nil) {
      self.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
  }
  
  func send() -> Void {
    var activityViewController: UIActivityViewController
    var openInAppActivity: TTOpenInAppActivity?
    
    if enableOpening! {
      openInAppActivity = TTOpenInAppActivity(view: self.view, andBarButtonItem: shareItem)
      activityViewController = UIActivityViewController(activityItems: [self.document.fileURL], applicationActivities: [openInAppActivity!])
    } else {
      activityViewController = UIActivityViewController(activityItems: [self.document.fileURL], applicationActivities: nil)
    }
    
    if !enablePrinting! {
      activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeCopyToPasteboard]
    }
    
    if !enableSharing! {
      var array: NSMutableArray = [UIActivityTypeAirDrop, UIActivityTypeCopyToPasteboard, UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTencentWeibo, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo] as NSMutableArray
      if (activityViewController.excludedActivityTypes!.count == 1){
        array.addObjectsFromArray(activityViewController.excludedActivityTypes!)
      }
      activityViewController.excludedActivityTypes = array
    }
    
    if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
      // Store reference to superview (UIActionSheet) to allow dismissal
      if (openInAppActivity != nil) {
        openInAppActivity!.superViewController = activityViewController
      }
      // Show UIActivityViewController
      self.presentViewController(activityViewController, animated:true, completion:nil)
    } else {
      // Create pop up
      self.activityPopoverController = UIPopoverController(contentViewController: activityViewController)
      // Store reference to superview (UIPopoverController) to allow dismissal
      if ((openInAppActivity) != nil) {
        openInAppActivity!.superViewController = self.activityPopoverController
      }
      // Show UIActivityViewController in popup
      self.activityPopoverController.presentPopoverFromBarButtonItem(
        shareItem,
        permittedArrowDirections: UIPopoverArrowDirection.Any,
        animated: true
      )
    }
  }
  
  func bookmark() -> Void {
    let currentPage: Int = Int(self.document.currentPage)
    if (self.document.bookmarks.containsIndex(currentPage)) {
      self.document.bookmarks.removeIndex(currentPage)
    } else {
      self.document.bookmarks.addIndex(currentPage)
    }
    resetNavigationToolbar()
  }
  
  func list() -> Void {
    self.toggleSinglePageView()
  }
  
  func toggleShowBookmarks (sender: UISegmentedControl) -> Void { // TODO: check the segmented control
    var control: UISegmentedControl = sender
    let isSelectedSegmentedIndex: Bool = (control.selectedSegmentIndex == 0)
    thumbsCollectionView.showBookmarkedPages(isSelectedSegmentedIndex)
  }
  
  /** Page Control **/
  
  func thumbCollectionView(thumbsCollectionView: PDFKBasicPDFViewerThumbsCollectionView, didSelectPage page: UInt) -> Void {
    self.pageCollectionView.displayPage(document.currentPage, animated:false)
    self.document.currentPage = UInt(page)
    self.pageScrubber.updateScrubber()
    self.toggleSinglePageView()
  }
  
  func scrubber(pageScrubber: PDFKPageScrubber, selectedPage page: Int) -> Void {
    self.document.currentPage = UInt(page)
    self.pageCollectionView.displayPage(document.currentPage, animated:false)
    self.resetNavigationToolbar()
    
  }
  
  func singlePageCollectionView(collectionView: PDFKBasicPDFViewerSinglePageCollectionView, didDisplayPage page:UInt) -> Void {
    self.document.currentPage = UInt(page)
    self.pageScrubber.updateScrubber()
    self.resetNavigationToolbar()
    
  }
  
  func nextPage() -> Void {
    document.currentPage += 1
    pageScrubber.updateScrubber()
    pageCollectionView.displayPage(document.currentPage, animated:true)
    self.resetNavigationToolbar()
  }
  
  func previousPage() -> Void {
    document.currentPage -= 1
    pageScrubber.updateScrubber()
    pageCollectionView.displayPage(document.currentPage, animated:true)
    self.resetNavigationToolbar()
    
  }
  
  func displayPage(page: UInt) -> Void {
    document.currentPage = page
    pageScrubber.updateScrubber()
    pageCollectionView.displayPage(document.currentPage, animated:true)
    self.resetNavigationToolbar()
  }
  
  
  /** Gestures **/
  
  func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if !showingSinglePage! {
      return false;
    }
    
    return true;
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
    var location: CGPoint = touch.locationInView(self.view)
    
    //We want to cancel the toggle gesture if we are on the toolbars while they are visible
    if navigationToolbar.hidden == false {
      if (CGRectContainsPoint(navigationToolbar.frame, location) || CGRectContainsPoint(pageScrubber.frame, location)) {
        return false
      }
    }
    
    return true
  }
  
  func handleSingleTap(gestureRecognizer: UITapGestureRecognizer) -> Void {
    //Check to see if the document was clicked.
    if (gestureRecognizer.state == UIGestureRecognizerState.Ended && showingSinglePage!) {
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
        var cell: PDFKBasicPDFViewerSinglePageCollectionViewCell = self.pageCollectionView.visibleCells()[0] as PDFKBasicPDFViewerSinglePageCollectionViewCell
        cell.pageContentView.zoomIncrement()
      } else {
        //Zoom out
        var cell: PDFKBasicPDFViewerSinglePageCollectionViewCell = self.pageCollectionView.visibleCells()[0] as PDFKBasicPDFViewerSinglePageCollectionViewCell
        cell.pageContentView.zoomDecrement()
      }
    }
  }
  
  /** Views **/
  
  func toggleToolbars() -> Void {
    
    if (showingSinglePage!) {
      if (navigationToolbar.hidden){
        //Show toolbars
        navigationToolbar.hidden = false
        pageScrubber.hidden = false
        UIView.animateWithDuration(
          Double(0.3),
          animations: {
            if (self.navigationToolbar.alpha == 0.0) {
              self.navigationToolbar.alpha = 1.0
            }
            if (self.pageScrubber.alpha == 0.0) {
              self.pageScrubber.alpha = 1.0
            }
          }
        )
      } else {
        //Hide toolbars
        UIView.animateWithDuration(
          Double(0.3),
          animations: {
            if (self.navigationToolbar.alpha == 1.0) {
              self.navigationToolbar.alpha = 0.0
            }
            if (self.pageScrubber.alpha == 1.0) {
              self.pageScrubber.alpha = 0.0
            }
          },
          completion: {(finished: Bool) -> Void in
            if finished {
              self.navigationToolbar.hidden = true
              self.pageScrubber.hidden = true
            }
          }
        )
      }
    }
  }
  
  func toggleSinglePageView() -> Void {
    if showingSinglePage! {
      //Show the thumbs view.
      showingSinglePage = false
      resetNavigationToolbar()
      thumbsCollectionView.showBookmarkedPages(false)
      thumbsCollectionView.reloadData()
      
      //Hide the slider if showing, show the nav bar if not showing
      navigationToolbar.hidden = false
      thumbsCollectionView.hidden = false
      
      UIView.animateWithDuration(
        Double(0.3),
        animations: {
          if (self.navigationToolbar.alpha == 0.0) {
            self.navigationToolbar.alpha = 1.0
          }
          if (self.pageScrubber.alpha == 1.0) {
            self.pageScrubber.alpha = 0.0
          }
          if (self.pageCollectionView.alpha == 1.0) {
            self.pageCollectionView.alpha = 0.0
          }
        },
        completion: {(finished: Bool) -> Void in
          self.pageScrubber.hidden = true
          self.pageCollectionView.hidden = true
        }
      )
    } else {
      showingSinglePage = true
      self.resetNavigationToolbar()
      pageScrubber.hidden = false
      pageCollectionView.hidden = false
      UIView.animateWithDuration(
        Double(0.3),
        animations: {
          if (self.pageScrubber.alpha == 0.0) {
            self.pageScrubber.alpha = 1.0
          }
          if (self.pageCollectionView.alpha == 0.0) {
            self.pageCollectionView.alpha = 1.0
          }
        },
        completion: {(finished: Bool) -> Void in
          //Hide so we don't have to render.
          self.thumbsCollectionView.hidden = true
        }
      )
    }
  }
  
}
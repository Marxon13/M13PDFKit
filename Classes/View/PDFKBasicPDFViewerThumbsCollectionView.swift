//
//  PDFKBasicPDFViewerThumbsCollectionView.swift
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

public protocol PDFKBasicPDFViewerThumbsCollectionViewDelegate {
    /**
    Lets the delegate know that the thumbs collection view did select a page.
    
    @param thumbsCollectionView The collection view.
    @param page                 The page selected.
    */
    func thumbsCollectionView(thumbsCollectionView: PDFKBasicPDFViewerThumbsCollectionView, didSelectPage page: page)
}

public class PDFKBasicPDFViewerThumbsCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------
    
    /**
    Initalize the collection view with a frame and a reader document.
    
    @param frame    The frame of the view.
    @param document The document to display thumbnails of.
    
    @return A thumbs collection view.
    */
    public init(frame: CGRect, document aDoc: PDFKDocument) {
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Vertical
        layout.sectionInset = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
        layout.minimumLineSpacing = 10.0
        layout.minimumInteritemSpacing = 10.0
        
        document = aDoc
        
        super.init(frame: frame, collectionViewLayout: collectionViewLayout)
        
        self.registerClass(PDFKBasicPDFViewerThumbsCollectionViewCell.self, forCellWithReuseIdentifier: "ThumbsCell")
        
        self.delegate = self
        self.dataSource = self
    }
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    /**
    The delegate that responds to page selection.
    */
    public var pageDelegate: PDFKBasicPDFViewerThumbsCollectionViewDelegate?
    
    /**
    The document to load thumbs from.
    */
    private let document: PDFKDocument
    
    /**
    The array of bookmarked pages to display.
    */
    private var bookmarkedPages: [Int] = []
    
    /**
    Wether or not we are showing bookmarked pages only.
    */
    public var showBookmarkedPages: Bool = false {
        willSet(newValue) {
            if newValue {
                document.bookmarks.enumerateIndexesUsingBlock({ (page, stop) -> Void in
                    bookmarkedPages.append(page)
                })
            } else {
                bookmarkedPages = []
            }
        }
        didSet {
            self.reloadData()
        }
    }
    
    //------------------------------------------
    /// @name Actions
    //------------------------------------------
    
    /**
    Scroll so that the cell for the given page is visible.
    
    @param page The page to scroll to.
    */
    public func scrollToPage(page: Int) {
        if !showBookmarkedPages {
            //The index path can just be based on the page number.
            let indexPath: NSIndexPath = NSIndexPath(forItem: page - 1, inSection: 0)
            self.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
        } else {
            //If the bookmarked page exists
            if let location: Int = find(bookmarkedPages, page) {
                let indexPath: NSIndexPath = NSIndexPath(forItem: location, inSection: 0)
                self.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
            }
        }
    }
    
    //------------------------------------------
    /// @name Collection View Data Source
    //------------------------------------------
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showBookmarkedPages ? bookmarkedPages.count ? document.pageCount
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone ? CGSizeMake(93.0, 120.0) : CGSizeMake(140.0, 180.0)
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: PDFKBasicPDFViewerThumbsCollectionViewCell = self.dequeueReusableCellWithReuseIdentifier("ThumbCell", forIndexPath: indexPath) as! PDFKBasicPDFViewerThumbsCollectionViewCell
        let pageToDisplay: Int = showBookmarkedPages ? bookmarkedPages[indexPath.row] : indexPath.row + 1
        
        //Set the page number
        cell.pageNumberLabel?.text = "\(pageToDisplay)"
        //Show bookmarked
        cell.showBookmark(document.bookmarks.containsIndex(pageToDisplay))
        //Load the thumb
        let request: PDFKThumbRequest = PDFKThumbRequest(thumbView: cell.thumbView!, fileURL: document.fileURL, password: document.password, guid: document.guid, pageNumber: pageToDisplay, ofSize: self.collectionView(self, layout: self.collectionViewLayout, sizeForItemAtIndexPath: indexPath))
        cell.thumbView?.showImage(PDFKThumbCache.sharedInstance().thumbWithThumbRequest(request, hasPriority: true))
        
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        (cell as! PDFKBasicPDFViewerThumbsCollectionViewCell).thumbView?.operation?.cancel()
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if !showBookmarkedPages {
            pageDelegate?.thumbsCollectionView(self, didSelectPage: indexPath.row)
        } else {
            pageDelegate?.thumbsCollectionView(self, didSelectPage: bookmarkedPages[indexPath.row])
        }
    }
}

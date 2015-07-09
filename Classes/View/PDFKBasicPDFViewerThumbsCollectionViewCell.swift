//
//  PDFKBasicPDFViewerThumbsCollectionViewCell.swift
//  
//
//  Created by Brandon McQuilkin on 7/8/15.
//
//

import UIKit

internal class PDFKBasicPDFViewerThumbsCollectionViewCell: UICollectionViewCell {
    
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------

    init() {
        super.init(frame: CGRectZero)
        setup()
    }
    
    init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        //Self
        self.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.layer.borderWidth = 0.5
        
        //Add the text label first so it is in the back
        pageNumberLabel = UILabel(frame: self.bounds)
        pageNumberLabel!.userInteractionEnabled = false
        pageNumberLabel!.textAlignment = NSTextAlignment.Center
        let fontSize: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad ? 19.0 : 16.0
        pageNumberLabel!.font = UIFont.systemFontOfSize(fontSize)
        pageNumberLabel!.textColor = UIColor.grayColor()
        pageNumberLabel!.backgroundColor = UIColor.whiteColor()
        pageNumberLabel!.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(pageNumberLabel!)
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: ["label": pageNumberLabel!]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: ["label": pageNumberLabel]))
        
        //Add the thumb view
        thumbView = PDFKThumbView(frame: self.bounds)
        thumbView!.userInteractionEnabled = false
        thumbView?.backgroundColor = UIColor.clearColor()
        thumbView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(thumbView!)
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[thumb]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: ["thumb": thumbView!]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[thumb]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: ["thumb": thumbView]))
        
        //Add the bookmark view last so it is on top
        bookmarkView = UIImageView(frame: CGRectMake(0, 0, 13, 21))
        bookmarkView!.contentMode = UIViewContentMode.Top
        bookmarkView!.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(bookmarkView!)
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[bookmark(13.0)-(5.0)-|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: ["bookmark": bookmarkView!]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[bookmark(21.0)]", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: ["bookmark": bookmarkView!]))
    }
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------

    /**
    The view that will display the thumb.
    */
    private(set) var thumbView: PDFKThumbView?
    
    /**
    The label that displays the page number while the thumb is loading.
    */
    private(set) var pageNumberLabel: UILabel?
    
    /**
    The image view that displays the bookmark image.
    */
    private(set) var bookmarkView: UIImageView?
    
    //------------------------------------------
    /// @name Actions
    //------------------------------------------

    /**
    Wether or not the page is bookmarked.
    
    @param show If YES, a bookmark will be displayed.
    */
    func showBookmark(show: Bool) {
        if show {
            bookmarkView!.image = UIImage(named: "Bookmarked")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        } else {
            bookmarkView!.image = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbView?.clearForReuse()
        pageNumberLabel?.text = nil
        bookmarkView?.image = nil
    }
}

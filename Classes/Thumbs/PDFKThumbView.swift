//
//  PDFKThumbView.swift
//  M13PDFKit
/*
Copyright (c) 2015 Brandon McQuilkin

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import UIKit

/**
A view that contains the thumbnail image for a page of a PDF Document.
*/
internal class PDFKThumbView: UIView {
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    //The image view used to display the rendered pdf.
    private var imageView: UIImageView
    
    /**
    The operation associated with the view.
    */
    internal var operation: NSOperation?
    
    /**
    The unique tag that identifies what the view is showing. It is a combination of the page number, width, and height of the thumb. This is used to check that the view has not been reused before setting the thumbnail of the view.
    */
    internal var targetTag: UInt = 0
    
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------
    
    override init(frame: CGRect) {
        
        imageView = UIImageView(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
        imageView.autoresizesSubviews = false
        imageView.userInteractionEnabled = false
        imageView.autoresizingMask = UIViewAutoresizing.None
        imageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        super.init(frame: frame)
        
        self.autoresizesSubviews = false
        self.userInteractionEnabled = false
        self.contentMode = UIViewContentMode.Redraw
        self.autoresizingMask = UIViewAutoresizing.None
        self.backgroundColor = UIColor.clearColor()
        
        self.addSubview(imageView)
        
        var constraints: [NSLayoutConstraint] = NSLayoutConstraint.constraintsWithVisualFormat("H:|[image]|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: ["image": imageView]) as! [NSLayoutConstraint]
        constraints += (NSLayoutConstraint.constraintsWithVisualFormat("V:|[image]|", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: ["image": imageView]) as! [NSLayoutConstraint])
        self.addConstraints(constraints)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //------------------------------------------
    /// @name Display
    //------------------------------------------
    /**
    Show the given image in the view.
    
    @param image The image to show.
    */
    internal func showImage(image: UIImage?) {
        imageView.image = image
    }
    
    /**
    Set wether or not the view is currently being touched. If it is being touched, Change the view accordingly.
    
    @note This is to be implemented by the subclass.
    
    @param touched Wether or not the view is currently being touched.
    */
    internal func showTouched(touched: Bool) {
        //Implemented by PDFKThumbView subclass.
    }
    
    //------------------------------------------
    /// @name Reset
    //------------------------------------------
    
    /**
    Clear the view's properties to allow for reuse of the view.
    */
    internal func clearForReuse() {
        targetTag = 0
        if let operation = operation {
            operation.cancel()
        }
        imageView.image = nil
    }
    
    override func removeFromSuperview() {
        targetTag = 0
        if let operation = operation {
            operation.cancel()
        }
        super.removeFromSuperview()
    }
}

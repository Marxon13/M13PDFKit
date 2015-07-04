//
//  PDFKPageScrubberThumb.swift
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

/**
The thumb view to display in the page bar.
*/
internal class PDFKPageScrubberThumbView: PDFKThumbView {
    
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------
    
    /**
    Create a new thumb view.
    
    @param frame The frame of the thumb view.
    @param small The alpha value of the thumb view.
    
    @return A new thumb view.
    */
    init(frame: CGRect, small: Bool) {
        super.init(frame: frame)
        
        //Calculate background color
        let alpha: CGFloat = small ? 0.6 : 0.7
        let background = UIColor(white: 0.8, alpha: alpha)
        self.backgroundColor = background
        self.imageView.backgroundColor = background
        imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        imageView.layer.borderWidth = 0.5
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override convenience init(frame: CGRect) {
        self.init(frame: frame, small: false)
    }
}
//
//  PDFKPageScrubberTrackControl.swift
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
The control that enables the scrubber to work. It calculates the percentage that you are across the width of the control, allowing the page number to be selected.
*/
internal class PDFKPageScrubberTrackControl: UIControl {
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    /**
    The value describing the horizontal distance from the origin across the control the last touch was.
    */
    private(set) var value: CGFloat = 0.0
    
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.autoresizesSubviews = false
        self.userInteractionEnabled = true
        self.contentMode = UIViewContentMode.Redraw
        self.autoresizingMask = UIViewAutoresizing.None
        self.backgroundColor = UIColor.clearColor()
        self.exclusiveTouch = true
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //------------------------------------------
    /// @name Internal Methods
    //------------------------------------------
    
    /**
    Limits the x position of a touch to 0 and bounds.width - 1.
    
    @param valueX The value to limit.
    */
    private func limitX(valueX: CGFloat) -> CGFloat {
        if valueX < self.bounds.origin.x {
            return self.bounds.origin.x
        }
        if valueX > self.bounds.size.width - 1.0 {
            return self.bounds.size.width - 1.0
        }
        return valueX
    }
    
    //------------------------------------------
    /// @name UIControl Methods
    //------------------------------------------
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) -> Bool {
        let point: CGPoint = touch.locationInView(self)
        value = limitX(point.x)
        self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
        return true
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) -> Bool {
        if self.touchInside {
            let point: CGPoint = touch.locationInView(self)
            let x: CGFloat = limitX(point.x)
            if x != value {
                value = x
                self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
            }
        }
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) {
        let point: CGPoint = touch.locationInView(self)
        let x: CGFloat = limitX(point.x)
        if x != value {
            value = x
            self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
        }
    }
}
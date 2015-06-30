//
//  PDFKThumbFetcher.swift
//  M13PDFKit
/*
Copyright (c) 2015 Brandon McQuilkin

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation
import ImageIO

internal class PDFKThumbFetcher: PDFKThumbOperation {
    
    //------------------------------------------
    /// @name Creation
    //------------------------------------------
    
    /**
    Initalize the thumb fetcher with an operation request.
    
    @param request The rendering request.
    
    @return A new thumb renderer.
    */
    internal override init(request aRequest: PDFKThumbRequest) {
        super.init(request: request)
    }
    
    //------------------------------------------
    /// @name Operation Methods
    //------------------------------------------
    
    override func cancel() {
        //Cancel and clean up
        super.cancel()
        request.thumbView?.operation = nil
        request.thumbView = nil
    }
    
    override func main() {
        var imageRef: CGImageRef?
        
        //Get the existing thumb image
        let loadRef: CGImageSourceRef! = CGImageSourceCreateWithURL(self.thumbFileURL() as! CFURLRef, nil)
        
        //If the image exists, load it
        if loadRef != nil {
            imageRef = CGImageSourceCreateImageAtIndex(loadRef, 0, nil)
        } else {
            // Existing thumb image not found - so create and queue up a thumb render operation on the work queue
            let thumbRenderer: PDFKThumbRenderer = PDFKThumbRenderer(request: self.request)
            thumbRenderer.queuePriority = self.queuePriority
            thumbRenderer.qualityOfService = NSQualityOfService.UserInteractive
            if !self.cancelled {
                // We're not cancelled - so update things and add the render operation to the work queue
                
                // Update the thumb view operation property to the new operation
                request.thumbView?.operation = thumbRenderer
                //Queue the operation
                PDFKThumbQueue.sharedQueue().addWorkOperation(thumbRenderer)
                return
            }
        }
        
        //Create a UIImage from a CGImage and show it.
        if imageRef != nil {
            if let image: UIImage = UIImage(CGImage: imageRef, scale: UIScreen.mainScreen().scale, orientation: UIImageOrientation.Up) {
                
                //Decode and draw the image on this background thread, The image is not decoded until it is drawn, Lets get it decoded now so that we don't block the UI thread with it later.
                UIGraphicsBeginImageContextWithOptions(image.size, true, UIScreen.mainScreen().scale)
                image.drawAtPoint(CGPointZero)
                let decoded: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext();
                
                //Cache
                PDFKThumbCache.sharedInstance().setImage(decoded, forKey: request.cacheKey)
                
                //Show the image in the target thumb view on the main thread
                //If the view's target has not changed, display the thumb.
                if !self.cancelled && request.targetTag == request.thumbView?.targetTag {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        request.thumbView?.showImage(decoded)
                    })
                }
            }
        }
        //Cleanup
        request.thumbView?.operation = nil
    }
}
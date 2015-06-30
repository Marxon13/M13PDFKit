//
//  PDFKThumbRenderer.swift
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

/**
Renders a thumbnail from the PDF to an image.
*/
internal class PDFKThumbRenderer: PDFKThumbOperation {
    
    //------------------------------------------
    /// @name Creation
    //------------------------------------------
    
    /**
    Initalize the thumb renderer with an operation request.
    
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
        
        var imageRef: CGImageRef!
        
        //Get the document
        if let thePDFDocRef = CGPDFDocumentCreate(request.fileURL, request.password) {
            //Get the page
            let thePDFPageRef: CGPDFPageRef! = CGPDFDocumentGetPage(thePDFDocRef, Int(request.thumbPage))
            if thePDFPageRef != nil {
                //Get the max thumb size
                let thumbW: CGFloat = request.thumbSize.width
                let thumbH: CGFloat = request.thumbSize.height
                
                //Setup for rendering
                let cropBoxRect: CGRect = CGPDFPageGetBoxRect(thePDFPageRef, kCGPDFCropBox)
                let mediaBoxRect: CGRect = CGPDFPageGetBoxRect(thePDFPageRef, kCGPDFMediaBox)
                let effectiveRect: CGRect = CGRectIntersection(cropBoxRect, mediaBoxRect)
                let pageRotate: Int32 = CGPDFPageGetRotationAngle(thePDFPageRef)
                
                //Get the rotated page size
                var pageW: CGFloat = 0.0
                var pageH: CGFloat = 0.0
                
                switch pageRotate { //Roation given in degrees
                    case 0, 180:
                        pageW = effectiveRect.size.width
                        pageH = effectiveRect.size.height
                        break
                    case 90, 270:
                        pageW = effectiveRect.size.height
                        pageH = effectiveRect.size.width
                        break
                    default:
                        break
                }
                
                //Get the scale of the thumb size to the page size
                let scaleW: CGFloat = thumbW / pageW
                let scaleH: CGFloat = thumbH / pageH
                var scale: CGFloat = 0.0
                //Calculate the scale
                if pageH > pageW {
                    //Portrait
                    scale = (thumbH > thumbW) ? scaleW : scaleH
                } else {
                    //Landscape
                    scale = (thumbH < thumbW) ? scaleH : scaleW
                }
                
                //Get the new target width and height
                var targetW: CGFloat = pageW * scale
                var targetH: CGFloat = pageH * scale
                
                //The thumb should be an even amount of pixels in size. The layout looks nicer this way.
                if targetW % 2 == 1 {
                    --targetW
                }
                if targetH % 2 == 1 {
                    --targetH
                }
                
                //Scale the size for the screen scale
                targetW *= UIScreen.mainScreen().scale
                targetH *= UIScreen.mainScreen().scale
                
                //Rendering setup
                let rgb: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
                let bmi: CGBitmapInfo = CGBitmapInfo.ByteOrder32Little | CGBitmapInfo(rawValue:CGImageAlphaInfo.NoneSkipFirst.rawValue)
                let context: CGContextRef! = CGBitmapContextCreate(nil, Int(targetW), Int(targetH), 8, 0, rgb, bmi)
                
                // Must have a valid custom CGBitmap context to draw into
                if context != nil {
                    //The rect to draw into the context frame
                    let thumbRect: CGRect = CGRectMake(0.0, 0.0, targetW, targetH)
                    
                    //Fill the rect
                    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0)
                    CGContextFillRect(context, thumbRect)
                    
                    //Transform the page ref to draw into the rect
                    CGContextConcatCTM(context, CGPDFPageGetDrawingTransform(thePDFPageRef, kCGPDFCropBox, thumbRect, 0, true))
                    
                    //Render
                    CGContextDrawPDFPage(context, thePDFPageRef)
                    
                    //FIXME Make sure that the document gets retained through the draw call? Hopefully not needed anymore
                    
                    //Get the image
                    imageRef = CGBitmapContextCreateImage(context)
                }
            }
        }
        
        //Create UIImage from CGImage and show it, then save thumb as PNG
        if imageRef != nil {
            if let image: UIImage = UIImage(CGImage: imageRef, scale: UIScreen.mainScreen().scale, orientation: UIImageOrientation.Up) {
                //Update the cache
                PDFKThumbCache.sharedInstance().setImage(image, forKey: request.cacheKey)
                
                ///Show the image in the target thumb view on the main thread
                //If the view's target has not changed, display the thumb.
                if !self.cancelled && request.targetTag == request.thumbView?.targetTag {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        request.thumbView?.showImage(image)
                    })
                }
            }
            
            //Save the thumb to file
            if let thumbNSURL: NSURL = self.thumbFileURL() {
                let thumbRef: CGImageDestinationRef! = CGImageDestinationCreateWithURL(thumbNSURL as CFURLRef, "public.png" as NSString as CFStringRef, 1, nil)
                if thumbRef != nil {
                    //Write to file
                    CGImageDestinationAddImage(thumbRef, imageRef, nil)
                    CGImageDestinationFinalize(thumbRef)
                }
            }
        }
        
        //Done!
        request.thumbView?.operation = nil
    }
}


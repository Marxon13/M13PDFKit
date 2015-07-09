//
//  PDFKPageContent.swift
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
The view that displays the PDF page. It is backed by a CATiledLayer
*/
internal class PDFKPageContent: UIView {
    
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------
    
    /**
    Initalize the page view.
    
    @param fileURL The PDF file to load.
    @param page    The page of the pdf file to load.
    @param phrase  The password to unlock the PDF file.
    
    @return A new view containing the content for the given PDF page.
    */
    init?(fileURL: NSURL, page aPage: Int, password phrase: String) {
        
        var viewRect: CGRect = CGRectZero
        
        if let aRef = CGPDFDocumentCreator.CGPDFDocumentCreate(fileURL, password: phrase) {
            docRef = aRef
            
            let pages: Int = CGPDFDocumentGetNumberOfPages(docRef)
            
            //Constrain page number
            var pageNumber: Int = aPage < 1 ? 1 : aPage
            pageNumber = pageNumber > pages ? pages : pageNumber
            
            if let aPageRef = CGPDFDocumentGetPage(docRef, pageNumber) {
                pageRef = aPageRef
                page = pageNumber
                
                let cropBoxRect: CGRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox)
                let mediaBoxRect: CGRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox)
                let effectiveRect: CGRect = CGRectIntersection(cropBoxRect, mediaBoxRect)
                
                pageAngle = CGPDFPageGetRotationAngle(pageRef)
                
                switch _pageAngle {
                case 0, 180:
                    pageSize.width = effectiveRect.size.width
                    pageSize.height = effectiveRect.size.height
                    pageOffset.x = effectiveRect.origin.x
                    pageOffset.y = effectiveRect.origin.y
                    break
                case 90, 270:
                    pageSize.width = effectiveRect.size.height
                    pageSize.height = effectiveRect.size.width
                    pageOffset.x = effectiveRect.origin.y
                    pageOffset.y = effectiveRect.origin.x
                    break
                default:
                    break
                }
                
                //Make the size even?
                var pageW = pageSize.width - (pageSize.width % 2)
                var pageH = pageSize.height - (pageSize.width % 2)
                
                //View size
                viewRect.size = CGSizeMake(pageW, pageH)
            } else {
                return nil
            }
        } else {
            return nil
        }
        
        super.init(frame: frame)
        
        buildAnnotationLinksList()
    }
    
    init?(frame: CGRect) {
        if CGRectIsEmpty(frame) == false {
            super.init(frame: frame)
            self.autoresizesSubviews = false
            self.userInteractionEnabled = false
            self.contentMode = UIViewContentMode.Redraw
            self.autoresizingMask = UIViewAutoresizing.None
            self.backgroundColor = UIColor.clearColor()
        } else {
            return nil
        }
    }
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    /**
    The document links in the page.
    */
    private var links: [PDFKDocumentLink] = []
    
    /**
    The refrence to the document.
    */
    private let docRef: CGPDFDocumentRef
    
    /**
    The refrence to the document page.
    */
    private let pageRef: CGPDFPageRef
    
    /**
    The angle of the page (0, 90, 180, 270)
    */
    private let pageAngle: Int
    
    /**
    The size of the page.
    */
    private let pageSize: CGSize
    
    /**
    The page offset.
    */
    private let pageOffset: CGPoint
    
    /**
    The page number
    */
    private let page: Int
    
    //------------------------------------------
    /// @name Actions
    //------------------------------------------
    
    /**
    Process a single tap on the view.
    
    @param recognizer The gesture recognizer that detected the single tap, for anotated links.
    
    @return The PDFKDocumentLink that was tapped.
    */
    func processSingleTap(recognizer: UITapGestureRecognizer) -> PDFKDocumentLink? {
        //Tap result object
        if recognizer.state == UIGestureRecognizerState.Ended {
            let point: CGPoint = recognizer.locationInView(self)
                
            for link in links {
                //Did we hit a link?
                if CGRectContainsPoint(link.rect, point) {
                    return annotationLinkTarget(link.infoDictionary)
                }
            }
        }
        
        return nil
    }
    
    //------------------------------------------
    /// @name Other
    //------------------------------------------
    
    override class func layerClass() -> AnyClass {
        return PDFKPageContentLayer
    }
    
    override func removeFromSuperview() {
        self.layer.delegate = nil
        super.removeFromSuperview()
    }
    
    override func drawLayer(layer: CALayer!, inContext ctx: CGContext!) {
        //Fill self
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0)
        CGContextFillRect(context, CGContextGetClipBoundingBox(context))
        
        //Translate for page
        CGContextTranslateCTM(context, 0.0, self.bounds.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        
        //Render
        CGContextDrawPDFPage(context, pageRef)
    }
    
    //------------------------------------------
    /// @name Links
    //------------------------------------------
    
    /**
    Add highlight views over all links.
    */
    private func highlightPageLinks() {
        let highlightColor: UIColor = self.tintColor != nil ? self.tintColor : UIColor(red: 0.11, green: 0.5, blue: 0.95, alpha: 1.0)
        for link in links {
            let highlight: UIView = UIView(frame: link.rect)
            
            highlight.autoresizesSubviews = false
            highlight.userInteractionEnabled = false
            highlight.contentMode = UIViewContentMode.Redraw
            highlight.autoresizingMask = UIViewAutoresizing.None
            highlight.backgroundColor = highlightColor
            
            self.addSubview(highlight)
        }
    }
    
    /**
    Create a link from an annotation.
    */
    private func linkFromAnnotation(annotation: CGPDFDictionaryRef) -> PDFKDocumentLink? {
        
        // Annotations co-ordinates array
        var annotationRectArray: CGPDFArrayRef = nil
        
        //If we can get the annotation's location and size, we need to convert that from PDF coordinates to view coordinates
        if CGPDFDictionaryGetArray(annotation, "Rect", &annotationRectArray) {
            //PDFRect lower-left X and Y
            var ll_x: CGPDFReal = 0.0
            var ll_y: CGPDFReal = 0.0
            //PDFRect upper-right X and Y
            var ur_x: CGPDFReal = 0.0
            var ur_y: CGPDFReal = 0.0
            
            //Lower-left
            CGPDFArrayGetNumber(annotationRectArray!, 0, &ll_x)
            CGPDFArrayGetNumber(annotationRectArray!, 1, &ll_y)
            //Upper-right
            CGPDFArrayGetNumber(annotationRectArray!, 2, &ur_x)
            CGPDFArrayGetNumber(annotationRectArray!, 3, &ur_y)
            
            //Normalize
            if ll_x > ur_x {
                let t = ll_x
                ll_x = ur_x
                ur_x = t
            }
            if ll_y > ur_y {
                let t = ll_y
                ll_y = ur_y
                ur_y = t
            }
            
            //Offset
            ll_x -= pageOffset.x
            ll_y -= pageOffset.y
            ur_x -= pageOffset.x
            ur_y -= pageOffset.y
            
            //Page rotation angle in degrees
            switch pageAngle {
            case 90:
                var swap: CGPDFReal = ll_y
                ll_y = ll_x
                ll_x = swap
                swap = ur_y
                ur_y = ur_x
                ur_x = swap
                break
            case 270:
                var swap: CGPDFReal = ll_y
                ll_y = ll_x
                ll_x = swap
                swap = ur_y
                ur_y = ur_x
                ur_x = swap
                ll_x = ((0.0 - ll_x) + pageSize.width)
                ur_x = ((0.0 - ur_x) + pageSize.width)
                break
            case 0:
                ll_y = ((0.0 - ll_y) + pageSize.height)
                ur_y = ((0.0 - ur_y) + pageSize.height)
                break
            default:
                break
            }
            
            //Integer X and width
            let vr_x: Int = Int(ll_x)
            let vr_w: Int = Int(ur_x - ll_x)
            
            //Integer Y and height
            let vr_y: Int = Int(ll_y)
            let vr_h: Int = Int(ur_y - ll_y)
            
            //View from PDFRect
            let rect: CGRect = CGRectMake(CGFloat(vr_x), CGFloat(vr_y), CGFloat(vr_w), CGFloat(vr_h))
            
            return PDFKDocumentLink(rect: rect, infoDictionary: annotation)
        }
        
        return nil
    }
    
    private func buildAnnotationLinksList() {
        links = []
        var pageAnnotations: CGPDFArrayRef? = nil
        
        //Get the dictionary of the page
        let pageDictionary: CGPDFDictionaryRef = CGPDFPageGetDictionary(pageRef)
        //Get the annotations of the page
        if CGPDFDictionaryGetArray(pageDictionary, "Annots", &pageAnnotations) {
            //Number of annotations
            let count: Int = CGPDFArrayGetCount(pageAnnotations!)
            
            for index in 0..<count {
                
                var annotationDictionary: CGPDFDictionaryRef? = nil
                if CGPDFArrayGetDictionary(pageAnnotations, index, &annotationDictionary) {
                    
                    //PDF annotation subtype string
                    var annotationSubtype: [CChar]? = nil
                    if CGPDFDictionaryGetName(annotationDictionary!, "Subtype", &annotationSubtype) {
                        //Is it a link?
                        if strcmp(annotationSubtype!, "Link") == 0 {
                            if let link: PDFKDocumentLink = linkFromAnnotation(annotationDictionary) {
                                links.insert(link, atIndex: 0)
                            }
                        }
                    }
                }
            }
            
            #if DEBUG
            //highlightPageLinks() //Link support debugging
            #endif
        }
    }
    
    private func destinationWithName(destinationName: [CChar] inDestsTree node: CGPDFDictionaryRef) -> CGPDFArrayRef? {
        var destinationArray: CGPDFArrayRef? = nil
        var limitsArray: CGPDFArrayRef? = nil
        
        //Check to see if we are outside of the node's limits
        if CGPDFDictionaryGetArray(node, "Limits", &limitsArray) {
            
            var lowerLimit: CGPDFStringRef? = nil
            var upperLimit: CGPDFStringRef? = nil
            
            //Get the lower and upper limits
            if CGPDFArrayGetString(limitsArray!, 0, &lowerLimit) && CGPDFArrayGetString(limitsArray, 1, &upperLimit) {
                
                let ll: [CChar] = CGPDFStringGetBytePtr(lowerLimit!)
                let ul: [CChar] = CGPDFStringGetBytePtr(upperLimit!)
                
                if strcmp(destinationName, ll!) < 0 || strcmp(destinationName, ul) > 0 {
                    return nil //Detination name is outside the node's limits
                }
            }
        }
        
        //Check to see if we have a names array
        var namesArray: CGPDFArrayRef = nil
        if CGPDFDictionaryGetArray(node, "Names", &namesArray) {
            let namesCount: Int = CGPDFArrayGetCount(namesArray!)
            
            for var index = 0; index < namesCount; index += 2 {
                //Destination name string
                var destName: CGPDFStringRef? = nil
                
                if CGPDFArrayGetString(namesArray, index, &destName) {
                    let dn: [CChar] = CGPDFStringGetBytePtr(destName!)
                    
                    //Did we find the destination name
                    if strcmp(dn, destinationName) == 0 {
                        if CGPDFArrayGetArray(namesArray, index + 1, &destinationArray) == false {
                            
                            var destinationDictionary: CGPDFDictionaryRef? = nil
                            if CGPDFArrayGetDictionary(namesArray, index + 1, &destinationDictionary) {
                                CGPDFDictionaryGetArray(destinationDictionary!, "D", &destinationArray)
                            }
                        }
                    }
                    
                    //We have a destination array
                    return destinationArray
                }
            }
        }
        
        //Check to see if we have a kids array
        var kidsArray: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetArray(node, "kids", &kidsArray) {
            let kidsCount: Int = CGPDFArrayGetCount(kidsArray!)
            
            for index in 0..< kidsCount {
                var kidsNode: CGPDFDictionaryRef = nil
                //Recurse into node
                if CGPDFArrayGetDictionary(kidsArray, index, &kidsNode) {
                    destinationArray = destinationWithName(destinationName, inDestsTree: kidsNode!)
                    return destinationArray
                }
            }
        }
    }
    
    func annotationLinkTarget(annotationDictionary: CGPDFDictionaryRef) -> AnyObject? {
        var linkTarget: AnyObject? = nil
        var destName: CGPDFStringRef? = nil
        var destString: [CChar]? = nil
        var actionDictionary: CGPDFDictionaryRef?
        var destArray: CGPDFArrayRef?
        
        if CGPDFDictionaryGetDictionary(annotationDictionary, "A", &actionDictionary) {
            
            //Annotation action type string
            var actionType: [CChar]?
            
            if CGPDFDictionaryGetName(actionDictionary, "S", &actionType) {
                //Goto action type
                if strcmp(actionType!, "GoTo") == 0 {
                    if CGPDFDictionaryGetArray(actionDictionary, "D", &destArray) {
                        CGPDFDictionaryGetString(actionDictionary, "D", &destName)
                    }
                } else {
                    //Handle other link type possibility
                    
                    //URI action type
                    if strcmp(actionType!, "URI") == 0 {
                        
                        var uriString: CGPDFStringRef?
                        if CGPDFDictionaryGetString(actionDictionary, "URI", &uriString) {
                            //Destination URI string
                            let uri: [CChar] = CGPDFStringGetBytePtr(uriString)
                            let target: String = NSString(CString: uri, encoding: NSUTF8StringEncoding)
                            linkTarget = NSURL(string: target.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding))
                            #if DEBUG
                                if linkTarget == nil {
                                    println("\(__FUNCTION__) Bad URI '\(target)'")
                                }
                            #endif
                        }
                    }
                }
            }
        } else {
            // Handle other link target posibilities
            if CGPDFDictionaryGetArray(annotationDictionary, "Dest", &destArray) == false {
                if CGPDFDictionaryGetString(annotationDictionary, "Dest", &destName) == false {
                    CGPDFDictionaryGetName(annotationDictionary, "Dest", &destString)
                }
            }
        }
        
        //Handle a destination name
        if let destName = destName {
            let catalogDictionary: CGPDFDictionaryRef = CGPDFDocumentGetCatalog(docRef)
            var namesDictionary: CGPDFDictionaryRef?
            
            if CGPDFDictionaryGetDictionary(catalogDictionary, "Names", &namesDictionary) {
                var destsDictionary: CGPDFDictionaryRef?
                if CGPDFDictionaryGetDictionary(namesDictionary, "Dests", &destDictionary) {
                    let destinationName: [CChar] = CGPDFStringGetBytePtr(destName)
                    destArray = destinationWithName(destinationName, inDestsTree: destsDictionary)
                }
            }
        }
        
        //Handle a destination string
        if let destString = destString {
            let catalogDictionary: CGPDFDictionaryRef = CGPDFDocumentGetCatalog(docRef)
            var destsDictionary: CGPDFDictionaryRef?
            
            if CGPDFDictionaryGetDictionary(catalogDictionary, "Dests", &destsDictionary) {
                var targetDictionary: CGPDFDictionaryRef?
                if CGPDFDictionaryGetDictionary(destsDictionary, destString, &targetDictionary) {
                    CGPDFDictionaryGetArray(targetDictionary, "D", &destArray)
                }
            }
        }
        
        //Handle a destination array
        if let destArray = destArray {
            var targetPageNumber: Int = 0
            var pageDictionaryFromDestArray: CGPDFDictionaryRef?
            
            if CGPDFArrayGetDictionary(destArray, 0, &pageDictionaryFromDestArray) {
                let pageCount: Int = CGPDFDocumentGetNumberOfPages(docRef)
                for pageNumber in 1...pageCount {
                    let pageRef: CGPDFPageRef = CGPDFDocumentGetPage(docRef, pageNumber)
                    let pageDictionaryFromPage: CGPDFDictionaryRef = CGPDFPageGetDictionary(pageRef)
                    
                    //Found it
                    if pageDictionaryFromPage == pageDictionaryFromDestArray {
                        targetPageNumber = pageNumber
                        break
                    }
                }
            } else {
                //Try page number from array possibility
                let pageNumber: CGPDFInteger = 0
                if CGPDFArrayGetInteger(destArray, 0, &pageNumber) {
                    targetPageNumber = pageNumber + 1 // 1... based
                }
            }
            
            //We have a target page number
            if targetPageNumber > 0 {
                linkTarget = NSNumber(integer: targetPageNumber)
            }
        }
        
        return linkTarget
    }
}
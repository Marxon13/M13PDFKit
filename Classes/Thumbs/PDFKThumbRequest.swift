//
//  PDFKThumbRequest.swift
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
import UIKit

/**
Stores information for thumbnail retreival.
*/
internal class PDFKThumbRequest: NSObject {
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    /**
    The URL of the pdf file associated with the request.
    */
    internal let fileURL: NSURL
    
    /**
    The GUID of the PDF document.
    */
    internal let guid: String
    
    /**
    The password to unlock the PDF file.
    */
    internal let password: String?
    
    /**
    The key to the cache.
    */
    internal let cacheKey: String
    
    /**
    The unique identifier of the thumb. Comprised of its page number, width and height.
    */
    internal let thumbName: String
    
    /**
    The view the request is for.
    */
    internal var thumbView: PDFKThumbView?
    
    /**
    The unique tag of the thumb view.
    */
    internal let targetTag: UInt
    
    /**
    The page of the PDF document the request is for.
    */
    internal let thumbPage: UInt
    
    /**
    The size of thumb the request is for.
    */
    internal let thumbSize: CGSize
    
    //------------------------------------------
    /// @name Initalization
    //------------------------------------------
    
    /**
    Create a new thumb request.
    
    @param view   The view the request is for.
    @param url    The URL of the PDF file the request is for.
    @param phrase The password to unlock the file.
    @param guid   The GUID of the PDF document.
    @param page   The page the request is for.
    @param size   The size of the tumbnail to request.
    
    @return A new request.
    */
    internal init(thumbView view: PDFKThumbView, fileURL url: NSURL, password phrase: String?, guid aGuid: String, pageNumber page: UInt, ofSize size: CGSize) {
        thumbView = view
        thumbPage = page
        thumbSize = size
        fileURL = url
        password = phrase
        guid = aGuid
        thumbName = "\(thumbPage)-\(thumbSize.width)x\(thumbSize.height)"
        cacheKey = "\(thumbName)+\(guid)"
        targetTag = UInt(cacheKey.hash)
        thumbView?.targetTag = targetTag
    }
}

//
//  PDFKThumbQueue.swift
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

/**
A queue that manages the operations that load PDF thumbs and operations that perform work on PDF thumbs.
*/
internal class PDFKThumbQueue: NSObject {
    
    //------------------------------------------
    /// @name Creation
    //------------------------------------------
    
    /**
    The shared queue.
    
    @return The instance of PDFKThumbQueue.
    */
    
    internal class func sharedQueue() -> PDFKThumbQueue {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: PDFKThumbQueue? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = PDFKThumbQueue()
        }
        return Static.instance!
    }
    
    private override init() {
        super.init()
        
        fetchQueue.name = "PDFKThumbFetchQueue"
        fetchQueue.maxConcurrentOperationCount = 1
        
        workQueue.name = "PDFKThumbWorkQueue"
        workQueue.maxConcurrentOperationCount = 1
    }
    
    //------------------------------------------
    /// @name Operation Management
    //------------------------------------------
    
    /**
    The queue for fetching thumbs.
    */
    private let fetchQueue: NSOperationQueue = NSOperationQueue()
    
    /**
    The queue for work operations.
    */
    private let workQueue: NSOperationQueue = NSOperationQueue()
    
    /**
    Add an operation to fetch/load a thumbnail.
    
    @param operation The operation to add to the queue.
    */
    internal func addFetchOperation(operation: PDFKThumbOperation) {
        fetchQueue.addOperation(operation)
    }
    
    /**
    Add an operation to perform work on a thumbnail.
    
    @param operation The operation to add to the queue.
    */
    internal func addWorkOperation(operation: PDFKThumbOperation)  {
        workQueue.addOperation(operation)
    }
    
    /**
    Cancel all operations in the queue coresponding to a PDF Document.
    
    @param guid The GUID of the PDF document to cancel operations for.
    */
    internal func cancelAllOperationsWithGUID(guid: String) {
        //Suspend the queues while we edit them
        fetchQueue.suspended = true
        workQueue.suspended = true
        
        //Remove the operations matching the GUID
        for operation in fetchQueue.operations as! [PDFKThumbOperation]{
            if operation.request.guid == guid {
                operation.cancel()
            }
        }
        for operation in workQueue.operations as! [PDFKThumbOperation]{
            if operation.request.guid == guid {
                operation.cancel()
            }
        }
        
        //Restart the queues
        fetchQueue.suspended = false
        workQueue.suspended = false
    }
    
    /**
    Cancel all operations in the queue.
    */
    internal func cancelAllOperations() {
        fetchQueue.cancelAllOperations()
        workQueue.cancelAllOperations()
    }
}

internal class PDFKThumbOperation: NSOperation {
    
    //------------------------------------------
    /// @name Properties
    //------------------------------------------
    
    /**
    The request containing the necessary info to render the PDF thumb.
    */
    internal let request: PDFKThumbRequest
    
    //------------------------------------------
    /// @name Creation
    //------------------------------------------
    
    /**
    Initalize the operation with a PDF's GUID.
    
    @param guid The GUID of the PDF the operation is for.
    
    @return A new operation instance.
    */
    internal init(request aRequest: PDFKThumbRequest) {
        request = aRequest
        super.init()
    }
    
    /**
    Returns the URL pointing to the thumb that the request is for.
    
    @return The NSURL location of the thumb.
    */
    internal func thumbFileURL() -> NSURL? {
        //Get the cache path
        let cachePath: String = PDFKThumbCache.thumbCachePathForGUID(request.guid)
        //Create the directory if necessary
        NSFileManager.defaultManager().createDirectoryAtPath(cachePath, withIntermediateDirectories: true, attributes: nil, error: nil)
        //Get the file name
        let fileName: String = "\(request.thumbName).png"
        //Create the URL
        return NSURL(fileURLWithPath: cachePath.stringByAppendingPathComponent(fileName))
    }
}
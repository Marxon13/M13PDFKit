//
//  PDFKThumbCache.swift
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

//The total cost of the cache. 25MB
internal let CACHE_SIZE: Int = 26214400

/**
Stores the thumbs for later reuse.
*/
internal class PDFKThumbCache: NSObject {
    
    //------------------------------------------
    /// @name Creation
    //------------------------------------------
    
    /**
    Get the shared thumb cache.
    
    @return The single cache instance.
    */
    internal class func sharedInstance() -> PDFKThumbCache {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: PDFKThumbCache? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = PDFKThumbCache()
        }
        return Static.instance!
    }
    
    /**
    Get the application cache directory. This won't change, so retreive it once, and store it.
    */
    private class func appCachesPath() -> String {
        struct StaticString {
            static var onceToken: dispatch_once_t = 0
            static var instance: String? = nil
        }
        dispatch_once(&StaticString.onceToken) {
            let cachesPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true) as! [String]
            StaticString.instance = cachesPaths.first!.stringByAppendingPathComponent("PDFKCache")
        }
        return StaticString.instance!
    }
    
    private override init() {
        super.init()
        cache.name = "PDFKThumbCache"
        cache.totalCostLimit = CACHE_SIZE
    }
    
    //------------------------------------------
    /// @name Cache Management
    //------------------------------------------
    
    /**
    Update the modification date of the thumb cache coresponding the the GUID.
    
    @param guid The GUID of the PDF document to update the cache for.
    */
    internal class func touchThumbCacheWithGUID(guid: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
            NSFileManager.defaultManager().setAttributes([NSFileModificationDate: NSDate()], ofItemAtPath: PDFKThumbCache.thumbCachePathForGUID(guid), error: nil)
        })
    }
    
    /**
    Creates the cache for the PDF document with the given GUID.
    
    @param guid The GUID of the PDF document to create the cache for.
    */
    internal class func createThumbCacheWithGUID(guid: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
            NSFileManager.defaultManager().createDirectoryAtPath(PDFKThumbCache.thumbCachePathForGUID(guid), withIntermediateDirectories: true, attributes: nil, error: nil)
        })
    }
    
    /**
    Removes the cache for the PDF document with the given GUID.
    
    @param guid The GUID of the PDF document to remove the cache of.
    */
    internal class func removeThumbCacheWithGUID(guid: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
            NSFileManager.defaultManager().removeItemAtPath(PDFKThumbCache.thumbCachePathForGUID(guid), error: nil)
        })
    }
    
    /**
    Deletes all caches older than the given age.
    
    @param age The time to determine what caches to expunge.
    */
    internal class func purgeThumbCachesOlderThan(age: NSTimeInterval) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
            let now: NSDate = NSDate()
            let fileManager: NSFileManager = NSFileManager.defaultManager()
            var cachePath: String = PDFKThumbCache.appCachesPath()
            
            //Get a list of all caches
            if let cachesList: [String] = fileManager.contentsOfDirectoryAtPath(PDFKThumbCache.appCachesPath(), error: nil) as? [String] {
                
                //Iterate through all the files
                for cacheName in cachesList {
                    
                    //Get cache attributes
                    if let attributes = fileManager.attributesOfItemAtPath(cachePath.stringByAppendingPathComponent(cacheName), error:nil) {
                        
                        //Get the last modification date
                        if let cacheDate = attributes[NSFileModificationDate] as? NSDate {
                            let fileAge: NSTimeInterval = now.timeIntervalSinceDate(cacheDate)
                            //If we are older, delete
                            if fileAge > age {
                                fileManager.removeItemAtPath(cachePath.stringByAppendingPathComponent(cacheName), error: nil)
                                #if DEBUG
                                println("Purged: \(cacheName)")
                                #endif
                            }
                        }
                    }
                }
            }
        })
    }
    
    /**
    Get the cache path for the PDF document with the given GUID.
    
    @param guid The guid of the PDF document to get the cache path for.
    
    @return The cache path for the PDF document with the given GUID.
    */
    internal class func thumbCachePathForGUID(guid: String) -> String {
        return PDFKThumbCache.appCachesPath().stringByAppendingPathComponent(guid)
    }
    
    //------------------------------------------
    /// @name Caching
    //------------------------------------------
    
    private let cache: NSCache = NSCache()
    
    /**
    @synchronized replacement for Swift.
    
    @param lock The object to lock on.
    @param closure The block to run.
    */
    private func synchronized(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    /**
    Retreives or create the given thumb for the thumb request.
    
    @param request The request for a given thumb.
    @param hasPriority If set to true, the thumb will be placed next in the queue. Otherwise the thumb request will be placed at the end of the queue.
    
    @return A UIImage of the given thumb.
    */
    internal func thumbWithThumbRequest(request: PDFKThumbRequest, hasPriority: Bool) -> UIImage? {
        //We only want one "Run" of this code running at a time. If multiple threads are running this code, we could recreate a thumb twice.
        var image: UIImage?
        synchronized(cache, closure: { () -> () in
            //See if the object already exists in the cache.
            if let object: UIImage = self.cache.objectForKey(request.cacheKey) as? UIImage {
                image = object
            } else {
                //FIXME removed NSNull placeholders, may not be necessary.
                //A thumb object does not yet exist. Fetch it
                let thumbFetcher: PDFKThumbFetcher = PDFKThumbFetcher(request: request)
                //Set the priority
                thumbFetcher.queuePriority = hasPriority ? NSOperationQueuePriority.Normal : NSOperationQueuePriority.Low
                request.thumbView?.operation = thumbFetcher
                thumbFetcher.qualityOfService = NSQualityOfService.Utility
                //Add it to the queue
                PDFKThumbQueue.sharedQueue().addFetchOperation(thumbFetcher)
            }
        })
        
        return image
    }
    
    /**
    Adds the given image to the cache with the given key.
    
    @param image: The image to add to the cache.
    @param key: The key for the image.
    */
    internal func setImage(image: UIImage, forKey key: String) {
        synchronized(cache, closure: { () -> () in
            let bytes: Int = Int(image.size.width * image.size.height * 4.0)
            self.cache.setObject(image, forKey: key, cost: bytes)
        })
    }
    
    /**
    Remove the object from the cache with the given key.
    
    @param key The key of the object to remove.
    */
    internal func removeImageForKey(key: String) {
        synchronized(cache, closure: { () -> () in
            self.cache.removeObjectForKey(key)
        })
    }
    
    /**
    Remove all objects from the cache.
    */
    internal func removeAllObjects() {
        synchronized(cache, closure: { () -> () in
            self.cache.removeAllObjects()
        })
    }
}
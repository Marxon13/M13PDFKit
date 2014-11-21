//
//	ReaderThumbCache.h
//	Reader v2.6.1
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright © 2011-2013 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PDFKThumbRequest;

/**
 Stores the thumbs for later reuse.
 */
@interface PDFKThumbCache : NSObject

/**
 Get the shared thumb cache.
 
 @return The single cache instance.
 */
+ (PDFKThumbCache *)sharedCache;
/**
 Update the modification date of the thumb cache coresponding the the GUID.
 
 @param guid The GUID of the PDF document to update the cache for.
 */
+ (void)touchThumbCacheWithGUID:(NSString *)guid;
/**
 Creates the cache for the PDF document with the given GUID.
 
 @param guid The GUID of the PDF document to create the cache for.
 */
+ (void)createThumbCacheWithGUID:(NSString *)guid;
/**
 Removes the cache for the PDF document with the given GUID.
 
 @param guid The GUID of the PDF document to remove the cache of.
 */
+ (void)removeThumbCacheWithGUID:(NSString *)guid;
/**
 Deletes all caches older than the given age.
 
 @param age The time to determine what caches to expunge.
 */
+ (void)purgeThumbCachesOlderThan:(NSTimeInterval)age;
/**
 Get the cache path for the PDF document with the given GUID.
 
 @param guid The guid of the PDF document to get the cache path for.
 
 @return The cache path for the PDF document with the given GUID.
 */
+ (NSString *)thumbCachePathForGUID:(NSString *)guid;

- (id)thumbRequest:(PDFKThumbRequest *)request priority:(BOOL)priority;

- (void)setObject:(UIImage *)image forKey:(NSString *)key;
/**
 Remove the object from the cache with the given key.
 
 @param key The key of the object to remove.
 */
- (void)removeObjectForKey:(NSString *)key;
/**
 Remove the placeholder object from the cache with the given key. A placeholder is set when the thumb is being worked on, or rendered.
 
 @param key The key of the placeholder to remove.
 */
- (void)removeNullForKey:(NSString *)key;
/**
 Remove all objects from the cache.
 */
- (void)removeAllObjects;

@end

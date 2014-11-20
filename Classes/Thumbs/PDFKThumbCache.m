//
//	ReaderThumbCache.m
//	Reader v2.6.0
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

#import "PDFKThumbCache.h"
#import "PDFKThumbQueue.h"
#import "PDFKThumbFetcher.h"
#import "PDFKThumbView.h"
#import "PDFKThumbRequest.h"

//The total cost of the cache. 10MB
#define CACHE_SIZE 10485760

@implementation PDFKThumbCache
{
	NSCache *thumbCache;
}

+ (PDFKThumbCache *)sharedCache
{
	static dispatch_once_t onceToken;
    static PDFKThumbCache *cache;
    dispatch_once(&onceToken, ^{
        cache = [self new];
    });
    return cache;
}

+ (NSString *)appCachesPath
{
    // Save a copy of the application caches path the first time it is needed
	static dispatch_once_t predicate = 0;
	static NSString *theCachesPath = nil;
	dispatch_once(&predicate, ^{
        NSArray *cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        theCachesPath = [[cachesPaths objectAtIndex:0] stringByAppendingPathComponent:@"PDFKCache"];
    });
	return theCachesPath;
}

+ (NSString *)thumbCachePathForGUID:(NSString *)guid
{
    //The cache for the PDF document with the given GUID
	NSString *cachesPath = [PDFKThumbCache appCachesPath];
	return [cachesPath stringByAppendingPathComponent:guid];
}

+ (void)createThumbCacheWithGUID:(NSString *)guid
{
	NSFileManager *fileManager = [NSFileManager new];
	NSString *cachePath = [PDFKThumbCache thumbCachePathForGUID:guid];
	[fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:NULL];
}

+ (void)removeThumbCacheWithGUID:(NSString *)guid
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSFileManager *fileManager = [NSFileManager new];
        NSString *cachePath = [PDFKThumbCache thumbCachePathForGUID:guid];
        [fileManager removeItemAtPath:cachePath error:NULL];
    });
}

+ (void)touchThumbCacheWithGUID:(NSString *)guid
{
	NSFileManager *fileManager = [NSFileManager new];
	NSString *cachePath = [PDFKThumbCache thumbCachePathForGUID:guid];
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
	[fileManager setAttributes:attributes ofItemAtPath:cachePath error:NULL];
}

+ (void)purgeThumbCachesOlderThan:(NSTimeInterval)age
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSDate *now = [NSDate date];
        //Get the list of all caches
        NSString *cachesPath = [PDFKThumbCache appCachesPath];
        NSFileManager *fileManager = [NSFileManager new];
        NSArray *cachesList = [fileManager contentsOfDirectoryAtPath:cachesPath error:NULL];
        
        if (cachesList != nil) {
            for (NSString *cacheName in cachesList) {
                //Get the cache attributes
                NSString *cachePath = [cachesPath stringByAppendingPathComponent:cacheName];
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:cachePath error:NULL];
                //Age of the cache
                NSDate *cacheDate = [attributes objectForKey:NSFileModificationDate];
                NSTimeInterval seconds = [now timeIntervalSinceDate:cacheDate];
                //If older than the age, remove
                if (seconds > age) {
                    [fileManager removeItemAtPath:cachePath error:NULL];
                    #ifdef DEBUG
                        NSLog(@"%s purged %@", __FUNCTION__, cacheName);
                    #endif
                }
            }
        }
    });
}

#pragma mark ReaderThumbCache instance methods

- (id)init
{
	if ((self = [super init]))
	{
		thumbCache = [NSCache new]; // Cache
		[thumbCache setName:@"PDFKThumbCache"];
		[thumbCache setTotalCostLimit:CACHE_SIZE];
	}
	return self;
}

- (id)thumbRequest:(PDFKThumbRequest *)request priority:(BOOL)priority
{
    //We only want one "Run" of this code running at a time. If multiple threads are running this code, we could recreate a thumb twice.
	@synchronized(thumbCache)
	{
        //See if the object exists in the cache.
		id object = [thumbCache objectForKey:request.cacheKey];
        
        //Thumb object does not yet exist in the cache, lets create it.
		if (object == nil)
		{
            //Return an NSNull thumb placeholder object
			object = [NSNull null];
			[thumbCache setObject:object forKey:request.cacheKey cost:2];
            
            //Create a fetching operation
			PDFKThumbFetcher *thumbFetch = [[PDFKThumbFetcher alloc] initWithRequest:request];
            //Set the priority
            [thumbFetch setQueuePriority:(priority ? NSOperationQueuePriorityNormal : NSOperationQueuePriorityLow)];
            request.thumbView.operation = thumbFetch;
            thumbFetch.qualityOfService = NSQualityOfServiceUtility;
            //Add it to the queue
			[[PDFKThumbQueue sharedQueue] addFetchOperation:thumbFetch];
		}
		return object;
	}
}

- (void)setObject:(UIImage *)image forKey:(NSString *)key
{
	@synchronized(thumbCache)
	{
        //Add the image to the cache
		NSUInteger bytes = (image.size.width * image.size.height * 4.0f);
		[thumbCache setObject:image forKey:key cost:bytes];
	}
}

- (void)removeObjectForKey:(NSString *)key
{
	@synchronized(thumbCache)
	{
		[thumbCache removeObjectForKey:key];
	}
}

- (void)removeNullForKey:(NSString *)key
{
	@synchronized(thumbCache)
	{
        //Remove the object only if it is a NSNull object.
		id object = [thumbCache objectForKey:key];
		if ([object isMemberOfClass:[NSNull class]])
		{
			[thumbCache removeObjectForKey:key];
		}
	}
}

- (void)removeAllObjects
{
	@synchronized(thumbCache)
	{
		[thumbCache removeAllObjects];
	}
}

@end


//
//	ReaderThumbQueue.m
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

#import "PDFKThumbQueue.h"

@implementation PDFKThumbQueue
{
    NSOperationQueue *fetchQueue;
	NSOperationQueue *workQueue;
}

+ (PDFKThumbQueue *)sharedQueue
{
    static dispatch_once_t onceToken;
    static PDFKThumbQueue *queue;
    dispatch_once(&onceToken, ^{
        queue = [self new];
    });
    return queue;
}

- (id)init
{
	if ((self = [super init])) {
		fetchQueue = [NSOperationQueue new];
		[fetchQueue setName:@"PDFKThumbFetchQueue"];
		[fetchQueue setMaxConcurrentOperationCount:1];
        
		workQueue = [NSOperationQueue new];
		[workQueue setName:@"PDFKThumbWorkQueue"];
		[workQueue setMaxConcurrentOperationCount:1];
	}
    
	return self;
}

- (void)addFetchOperation:(NSOperation *)operation
{
	if ([operation isKindOfClass:[PDFKThumbOperation class]])
	{
		[fetchQueue addOperation:operation];
	}
}

- (void)addWorkOperation:(NSOperation *)operation
{
	if ([operation isKindOfClass:[PDFKThumbOperation class]])
	{
		[workQueue addOperation:operation];
	}
}

- (void)cancelOperationsWithGUID:(NSString *)guid
{
    //Suspend the queues while we edit them.
	[fetchQueue setSuspended:YES];
    [workQueue setSuspended:YES];
    
    //Remove the operations matching the GUID
	for (PDFKThumbOperation *operation in fetchQueue.operations)
	{
		if ([operation isKindOfClass:[PDFKThumbOperation class]])
		{
			if ([operation.guid isEqualToString:guid]) {
                [operation cancel];
            }
		}
	}
    
	for (PDFKThumbOperation *operation in workQueue.operations)
	{
		if ([operation isKindOfClass:[PDFKThumbOperation class]])
		{
			if ([operation.guid isEqualToString:guid]) {
               [operation cancel];
            }
		}
	}
    
    //Restart the queues
	[workQueue setSuspended:NO];
    [fetchQueue setSuspended:NO];
}

- (void)cancelAllOperations
{
	[fetchQueue cancelAllOperations];
    [workQueue cancelAllOperations];
}

@end

@implementation PDFKThumbOperation

- (id)initWithGUID:(NSString *)guid
{
	if ((self = [super init])) {
		_guid = guid;
	}
	return self;
}

@end

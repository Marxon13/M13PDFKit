//
//	ReaderThumbQueue.h
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

#import <Foundation/Foundation.h>

/**
 A queue that manages the operations that load PDF thumbs and operations that perform work on PDF thumbs.
 */
@interface PDFKThumbQueue : NSObject

/**
 The shared queue.
 
 @return The instance of PDFKThumbQueue.
 */
+ (PDFKThumbQueue *)sharedQueue;
/**
 Add an operation to fetch/load a thumbnail.
 
 @param operation The operation to add to the queue.
 */
- (void)addFetchOperation:(NSOperation *)operation;
/**
 Add an operation to perform work on a thumbnail.
 
 @param operation The operation to add to the queue.
 */
- (void)addWorkOperation:(NSOperation *)operation;
/**
 Cancel all operations in the queue coresponding to a PDF Document.
 
 @param guid The GUID of the PDF document to cancel operations for.
 */
- (void)cancelOperationsWithGUID:(NSString *)guid;
/**
 Cancel all operations in the queue.
 */
- (void)cancelAllOperations;

@end

/**
 An operation on a thumb that will be handled by the queue.
 */
@interface PDFKThumbOperation : NSOperation

/**
 The GUID of the PDF that the operations is associated with.
 */
@property (nonatomic, strong, readonly) NSString *guid;
/**
 Initalize the operation with a PDF's GUID.
 
 @param guid The GUID of the PDF the operation is for.
 
 @return A new operation instance.
 */
- (id)initWithGUID:(NSString *)guid;

@end

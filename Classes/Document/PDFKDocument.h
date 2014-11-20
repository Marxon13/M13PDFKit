//
//	ReaderDocument.h
//	Reader v2.6.0
//
//	Created by Julius Oklamcak on 2011-07-01.
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

/**
 A object that represents a single PDF File.
 */
@interface PDFKDocument : NSObject <NSObject, NSCoding>

/**@name Document Properties*/
/**
 The current/last page that the document displaied.
 */
@property (nonatomic, assign, readwrite) NSUInteger currentPage;
/**
 The set of numbers defining the bookmarked pages.
 */
@property (nonatomic, strong, readonly) NSMutableIndexSet *bookmarks;
/**
 The password to open the PDF file if necessary.
 */
@property (nonatomic, strong, readonly) NSString *password;
/**
 The URL location of the PDF file.
 */
@property (nonatomic, strong, readonly) NSURL *fileURL;
/**
 The globally unique identifier for the PDF document.
 */
@property (nonatomic, strong, readonly) NSString *guid;
/**
 The last time the PDF file was opened.
 */
@property (nonatomic, strong, readwrite) NSDate *lastOpenedDate;
/**
 The size of the PDF file in bytes.
 */
@property (nonatomic, assign, readonly) NSUInteger fileSize;
/**
 The total number of pages in the PDF document.
 */
@property (nonatomic, assign, readonly) NSUInteger pageCount;

/**@name File Properties*/
/**
 The title of the PDF document.
 */
@property (nonatomic, strong, readonly) NSString *title;
/**
 The author of the PDF document.
 */
@property (nonatomic, strong, readonly) NSString *author;
/**
 The subject of the document.
 */
@property (nonatomic, strong, readonly) NSString *subject;
/**
 Keywords decribing the document's contents.
 */
@property (nonatomic, strong, readonly) NSString *keywords;
/**
 The creator of the PDF.
 */
@property (nonatomic, strong, readonly) NSString *creator;
/**
 The producer of the PDF.
 */
@property (nonatomic, strong, readonly) NSString *producer;
/**
 The last time the PDF file was modified.
 */
@property (nonatomic, strong, readonly) NSDate *modificationDate;
/**
 The date the PDF was created.
 */
@property (nonatomic, strong, readonly) NSDate *creationDate;
/**
 The PDF version.
 */
@property (nonatomic, assign, readonly) CGFloat version;

/**@name Creation*/
/**
 Creates a PDF document from the PDF file at the given path. Unarchiving it if necessary.
 
 @note This method should be the method used to create the PDF document, it handles unarchiving the document for you. If the document archive does not exist, a new document is created.
 
 @param filePath The path of the PDF file to load.
 @param password The password to unlock the PDF file if necessary.
 
 @return A new PDFKDocument.
 */
+ (PDFKDocument *)documentWithContentsOfFile:(NSString *)filePath password:(NSString *)password;
/**
 Unarchive the stored document information and create a PDF document from the PDF file at the given path.
 
 @param filePath The path of the PDF file to load.
 @param password The password to unlock the PDF file if necessary.
 
 @return A new PDFKDocument.
 */
+ (PDFKDocument *)unarchiveDocumentForContentsOfFile:(NSString *)filePath password:(NSString *)password;
/**
 Initalize a PDF document from the PDF file at the given path.
 
 @param filePath The path of the PDF file to load.
 @param password The password to unlock the PDF file if necessary.
 
 @return A new PDFKDocument.
 */
- (id)initWithContentsOfFile:(NSString *)filePath password:(NSString *)password;
/**
 Save the document information to the archive.
 */
- (void)saveReaderDocument;
/**
 Reload the document properties from the PDF file.
 */
- (void)updateProperties;

@end

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
#import <CommonCrypto/CommonCrypto.h>
#import "PDFKDocument.h"
#import "CGPDFDocument.h"

static inline NSString *NSStringCCHashFunction(unsigned char *(function)(const void *data, CC_LONG len, unsigned char *md), CC_LONG digestLength, NSString *string)
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[digestLength];
    
    function(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:digestLength * 2];
    
    for (int i = 0; i < digestLength; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

@implementation PDFKDocument

#pragma mark - Creation

+ (PDFKDocument *)unarchiveDocumentForContentsOfFile:(NSString *)filePath password:(NSString *)password
{
	PDFKDocument *document = nil;
    
    //Get the archive of the PDF
	NSString *archiveFilePath = [PDFKDocument archiveFilePathForFileAtPath:filePath];
    
    //Unarchive an archived ReaderDocument object from its property list
	@try {
		document = [NSKeyedUnarchiver unarchiveObjectWithFile:archiveFilePath];
		if ((document != nil) && (password != nil)) { // Set the document password
			[document setValue:[password copy] forKey:@"password"];
		}
        
	} @catch (NSException *exception) { // Exception handling (just in case O_o)
#ifdef DEBUG
        NSLog(@"%s Caught %@: %@", __FUNCTION__, [exception name], [exception reason]);
#endif
	}
    
	return document;
}

+ (PDFKDocument *)documentWithContentsOfFile:(NSString *)filePath password:(NSString *)password
{
	PDFKDocument *document = nil;
    
	document = [PDFKDocument unarchiveDocumentForContentsOfFile:filePath password:password];
    
    //Unarchive failed so we create a new ReaderDocument object
	if (document == nil) {
		document = [[PDFKDocument alloc] initWithContentsOfFile:filePath password:password];
	}
    
	return document;
}


- (id)initWithContentsOfFile:(NSString *)filePath password:(NSString *)password
{
	id object = nil;
    //Does the PDF exist, and is it a PDF
	if ([PDFKDocument isPDF:filePath] == YES) {
		if ((self = [super init])) {
            //Set the initial properties
			_guid = [PDFKDocument GUID];
			_password = [password copy];
			_bookmarks = [NSMutableIndexSet new];
			_currentPage = 1;
            _fileURL = [[NSURL alloc] initFileURLWithPath:filePath isDirectory:NO];
            
            [self loadDocumentInformation];
            
			_lastOpenedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0.0];
            
            //Save the document information to the archive.
			[self saveReaderDocument];
            
			object = self;
		}
	}
    
	return object;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init])) // Superclass init
	{
		_guid = [decoder decodeObjectForKey:@"FileGUID"];
		_currentPage = ((NSNumber *)[decoder decodeObjectForKey:@"CurrentPage"]).unsignedIntegerValue;
		_bookmarks = [decoder decodeObjectForKey:@"Bookmarks"];
		_lastOpenedDate = [decoder decodeObjectForKey:@"LastOpen"];
        _fileURL = [NSURL fileURLWithPath:[decoder decodeObjectForKey:@"URL"]];
		if (_guid == nil) _guid = [PDFKDocument GUID];
		if (_bookmarks != nil)
			_bookmarks = [_bookmarks mutableCopy];
		else
			_bookmarks = [NSMutableIndexSet new];
        [self loadDocumentInformation];
	}
    
	return self;
}

- (void)loadDocumentInformation
{
    //Load the document
    CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreate(_fileURL, _password);
    if (thePDFDocRef == NULL) {
        //This shouldn't happen
        NSAssert(NO, @"CGPDFDocumentRef == NULL");
    }
    //Load the information dictionary
    CGPDFDictionaryRef infoDict = CGPDFDocumentGetInfo(thePDFDocRef);
    CGPDFStringRef string;
    
    //Title
    if (CGPDFDictionaryGetString(infoDict, "Title", &string)) {
        CFStringRef ref = CGPDFStringCopyTextString(string);
        if (ref != NULL) {
            _title = (NSString *)CFBridgingRelease(ref);
        }
    }
    
    //Author
    if (CGPDFDictionaryGetString(infoDict, "Author", &string)) {
        CFStringRef ref = CGPDFStringCopyTextString(string);
        if (ref != NULL) {
            _author = (NSString *)CFBridgingRelease(ref);
        }
    }
    
    //Subject
    if (CGPDFDictionaryGetString(infoDict, "Subject", &string)) {
        CFStringRef ref = CGPDFStringCopyTextString(string);
        if (ref != NULL) {
            _subject = (NSString *)CFBridgingRelease(ref);
        }
    }
    
    //Keywords
    if (CGPDFDictionaryGetString(infoDict, "Keywords", &string)) {
        CFStringRef ref = CGPDFStringCopyTextString(string);
        if (ref != NULL) {
            _keywords = (NSString *)CFBridgingRelease(ref);
        }
    }
    
    //Creator
    if (CGPDFDictionaryGetString(infoDict, "Creator", &string)) {
        CFStringRef ref = CGPDFStringCopyTextString(string);
        if (ref != NULL) {
            _creator = (NSString *)CFBridgingRelease(ref);
        }
    }
    
    //Producer
    if (CGPDFDictionaryGetString(infoDict, "Producer", &string)) {
        CFStringRef ref = CGPDFStringCopyTextString(string);
        if (ref != NULL) {
            _producer = (NSString *)CFBridgingRelease(ref);
        }
    }
    
    //CreationDate
    if (CGPDFDictionaryGetString(infoDict, "CreationDate", &string)) {
        CFDateRef date = CGPDFStringCopyDate(string);
        if (date != NULL) {
            _creationDate = (NSDate *)CFBridgingRelease(date);
        }
    }
    
    //ModificationDate
    if (CGPDFDictionaryGetString(infoDict, "ModDate", &string)) {
        CFDateRef date = CGPDFStringCopyDate(string);
        if (date != NULL) {
            _modificationDate = (NSDate *)CFBridgingRelease(date);
        }
    }
    
    //Version
    int majorVersion, minorVersion;
    CGPDFDocumentGetVersion(thePDFDocRef, &majorVersion, &minorVersion);
    NSString *versionString = [NSString stringWithFormat:@"%d.%d", majorVersion, minorVersion];
    _version = versionString.floatValue;

    //Page Count
    _pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef);
    
    //File Size
    NSFileManager *fileManager = [NSFileManager new];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[_fileURL path] error:nil];
    _fileSize = ((NSNumber *)[fileAttributes objectForKey:NSFileSize]).unsignedIntegerValue; // File size (bytes)
    
    //Cleanup
    CGPDFDocumentRelease(thePDFDocRef);
}

#pragma mark - Helper Methods
+ (NSString *)GUID
{
    //Create a globally unique string.
	return [[NSProcessInfo processInfo] globallyUniqueString];
}

+ (NSString *)documentsPath
{
    //Get the document folder path.
	return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

+ (NSString *)applicationPath
{
    //Get the folder that the application is contained in.
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [[documentsPaths objectAtIndex:0] stringByDeletingLastPathComponent]; // Strip "Documents" component
}

+ (NSString *)applicationSupportPath
{
    //Path to the application's "~/Library/Application Support" directory
	NSFileManager *fileManager = [NSFileManager new];
	NSURL *pathURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
	return [pathURL path];
}

+ (NSString *)archiveFilePathForFileAtPath:(NSString *)path
{
	assert(path != nil); // Ensure that the archive file name is not nil
	NSString *archivePath = [PDFKDocument applicationSupportPath]; // Application's "~/Library/Application Support" path
	NSString *archiveName = [NSStringCCHashFunction(CC_SHA256, CC_SHA256_DIGEST_LENGTH, path) stringByAppendingPathExtension:@"plist"];
	return [archivePath stringByAppendingPathComponent:archiveName];
}

+ (BOOL)isPDF:(NSString *)filePath
{
    //Check to see if a file is a PDF
	BOOL state = NO;
    
	if (filePath != nil) { // Must have a file path
		const char *path = [filePath fileSystemRepresentation];
        
		int fd = open(path, O_RDONLY); // Open the file
        
		if (fd > 0) // We have a valid file descriptor
		{
			const char sig[1024]; // File signature buffer
            
			ssize_t len = read(fd, (void *)&sig, sizeof(sig));
            
			state = (strnstr(sig, "%PDF", len) != NULL);
            
			close(fd); // Close the file
		}
	}
    
	return state;
}

- (BOOL)archiveWithFileAtPath:(NSString *)filePath
{
    NSString *archiveFilePath = [PDFKDocument archiveFilePathForFileAtPath:filePath];
	return [NSKeyedArchiver archiveRootObject:self toFile:archiveFilePath];
}

- (void)saveReaderDocument
{
    [self archiveWithFileAtPath:_fileURL.path];
}

- (void)updateProperties
{
	[self loadDocumentInformation];
}

- (void)setCurrentPage:(NSUInteger)currentPage
{
    if (currentPage < 1) {
        currentPage = 1;
    } else if (currentPage > _pageCount) {
        currentPage = _pageCount;
    }
    _currentPage = currentPage;
}

#pragma mark NSCoding protocol methods

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:_guid forKey:@"FileGUID"];
	[encoder encodeObject:[NSNumber numberWithUnsignedInteger:_currentPage] forKey:@"CurrentPage"];
	[encoder encodeObject:_bookmarks forKey:@"Bookmarks"];
	[encoder encodeObject:_lastOpenedDate forKey:@"LastOpen"];
    [encoder encodeObject:[_fileURL path] forKey:@"URL"];
}


@end

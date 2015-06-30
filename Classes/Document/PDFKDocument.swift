//
//  PDFKDocument.swift
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

import Foundation

/**
A object that represents a single PDF File.
*/
@objc public class PDFKDocument: NSObject, NSCoding {
    //------------------------------------------
    /// @name Document Properties
    //------------------------------------------
    
    /**
    The current/last page that the document displaied.
    */
    public var currentPage: UInt = 0 {
        didSet {
            if currentPage < 1 {
                currentPage = 1
            } else if currentPage > pageCount {
                currentPage = pageCount
            }
        }
    }
    /**
    The set of numbers defining the bookmarked pages.
    */
    public private(set) var bookmarks: NSMutableIndexSet = NSMutableIndexSet()
    
    /**
    The password to open the PDF file if necessary.
    */
    public private(set) var password: String?
    
    /**
    The URL location of the PDF file.
    */
    public private(set) var fileURL: NSURL!
    
    /**
    The globally unique identifier for the PDF document.
    */
    public private(set) var guid: String = NSProcessInfo.processInfo().globallyUniqueString
    
    /**
    The last time the PDF file was opened.
    */
    public var lastOpenedDate: NSDate = NSDate()
    
    /**
    The size of the PDF file in bytes.
    */
    public private(set) var fileSize: UInt64 = 0

    /**
    The total number of pages in the PDF document.
    */
    public private(set) var pageCount: UInt = 0
    
    //------------------------------------------
    /// @name File Properties
    //------------------------------------------
    
    /**
    The title of the PDF document.
    */
    public private(set) var title: String?
    
    /**
    The author of the PDF document.
    */
    public private(set) var author: String?
    
    /**
    The subject of the document.
    */
    public private(set) var subject: String?

    /**
    Keywords decribing the document's contents.
    */
    public private(set) var keywords: String?
    
    /**
    The creator of the PDF.
    */
    public private(set) var creator: String?

    /**
    The producer of the PDF.
    */
    public private(set) var producer: String?

    /**
    The last time the PDF file was modified.
    */
    public private(set) var modificationDate: NSDate?
    
    /**
    The date the PDF was created.
    */
    public private(set) var creationDate: NSDate?

    /**
    The PDF version.
    */
    public private(set) var version: Float?
    
    //------------------------------------------
    /// @name Creation
    //------------------------------------------
    
    /**
    Creates a PDF document from the PDF file at the given path. Unarchiving it if necessary.
    
    @note This method should be the method used to create the PDF document, it handles unarchiving the document for you. If the document archive does not exist, a new document is created.
    
    @param filePath The path of the PDF file to load.
    @param password The password to unlock the PDF file if necessary.
    
    @return A new PDFKDocument.
    */
    public class func documentWithContentsOfFile(filePath: String, password: String?) -> PDFKDocument? {
        //Try unarchiving first
        if let document = PDFKDocument.unarchiveDocumentForContentsOfFile(filePath, password: password) {
            return document
        }
        //Create a new document if possible
        return PDFKDocument(fileAtPath: filePath, password: password)
    }

    /**
    Unarchive the stored document information and create a PDF document from the PDF file at the given path.
    
    @param filePath The path of the PDF file to load.
    @param password The password to unlock the PDF file if necessary.
    
    @return A new PDFKDocument.
    */
    public class func unarchiveDocumentForContentsOfFile(filePath: String, password: String?) -> PDFKDocument? {
        var document: PDFKDocument?
        
        //Get the archive of the pdf
        let archiveFilePath: String? = PDFKDocument.archiveFilePathForFileAtPath(filePath)
        
        if let archiveFilePath = archiveFilePath {
            
            //Does the archive exist?
            if !NSFileManager.defaultManager().fileExistsAtPath(archiveFilePath) {
                return nil
            }
            
            //Load the archive
            //FIXME
            //Add exception handling using swift 2. Sadly @try does not exist.
            //@try {
            document = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? PDFKDocument
            document?.password = password
            //} @catch (NSException *exception) {
            //NSLog(@"%s Caught %@: %@", __FUNCTION__, [exception name], [exception reason]);
            //}
        }
    
        return document
    }

    /**
    Initalize a PDF document from the PDF file at the given path.
    
    @param filePath The path of the PDF file to load.
    @param password The password to unlock the PDF file if necessary.
    
    @return A new PDFKDocument.
    */
    public required init?(fileAtPath filePath: String, password aPassword: String?) {
        super.init()
        
        //Do we have a valid URL?
        if let url = NSURL(fileURLWithPath: filePath) {
            fileURL = url
            password = aPassword
        } else {
            //Invalid URL, fail
            return nil
        }
        
        //Does the pdf exist?
        if PDFKDocument.isPDF(filePath) {
            //Load the PDF sepcific info
            loadDocumentInformation()
            //Save the info to the archive
            saveDocument()
        } else {
            //Not a PDF, fail
            return nil
        }
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init()
        
        if let aguid = aDecoder.decodeObjectForKey("FileGUID") as? String {
            guid = aguid
        }
        currentPage = UInt(aDecoder.decodeIntegerForKey("CurrentPage"))
        if let aBookmarks = aDecoder.decodeObjectForKey("Bookmarks") as? NSIndexSet {
            bookmarks = aBookmarks.mutableCopy() as! NSMutableIndexSet
        }
        if let aLastOpenDate = aDecoder.decodeObjectForKey("LastOpen") as? NSDate {
            lastOpenedDate = aLastOpenDate
        }
        if let aFileURL = aDecoder.decodeObjectForKey("URL") as? NSURL {
            fileURL = aFileURL
        }
        
        loadDocumentInformation()
    }
    
    //------------------------------------------
    /// @name Updating/Verifying
    //------------------------------------------
    
    /**
    Reload the document properties from the PDF file.
    */
    public func updateDocumentProperties() {
        loadDocumentInformation()
    }
    
    /**
    Loads the PDF document metadata.
    */
    private func loadDocumentInformation() {
        //Load the document
        if let thePDFDocRef = CGPDFDocumentCreate(fileURL, password) {
            //Load the information dictionary
            let infoDict: CGPDFDictionaryRef = CGPDFDocumentGetInfo(thePDFDocRef)
            var string: CGPDFStringRef = CGPDFStringRef()
            
            //Title
            if CGPDFDictionaryGetString(infoDict, "Title", &string) {
                if let aTitle = convertCFSStringTypeToString(CGPDFStringCopyTextString(string)) {
                    title = aTitle
                }
            }
            
            //Author
            if CGPDFDictionaryGetString(infoDict, "Author", &string) {
                if let anAuthor = convertCFSStringTypeToString(CGPDFStringCopyTextString(string)) {
                    author = anAuthor
                }
            }
            
            //Subject
            if CGPDFDictionaryGetString(infoDict, "Subject", &string) {
                if let aSubject = convertCFSStringTypeToString(CGPDFStringCopyTextString(string)) {
                    subject = aSubject
                }
            }
            
            //Keywords
            if CGPDFDictionaryGetString(infoDict, "Keywords", &string) {
                if let aKeywords = convertCFSStringTypeToString(CGPDFStringCopyTextString(string)) {
                    keywords = aKeywords
                }
            }
            
            //Creator
            if CGPDFDictionaryGetString(infoDict, "Creator", &string) {
                if let aCreator = convertCFSStringTypeToString(CGPDFStringCopyTextString(string)) {
                    creator = aCreator
                }
            }
            
            //Producer
            if CGPDFDictionaryGetString(infoDict, "Producer", &string) {
                if let aProducer = convertCFSStringTypeToString(CGPDFStringCopyTextString(string)) {
                    producer = aProducer
                }
            }
            
            //CreationDate
            if CGPDFDictionaryGetString(infoDict, "CreationDate", &string) {
                if let aCreationDate = convertCFDateTypeToNSDate(CGPDFStringCopyDate(string)) {
                    creationDate = aCreationDate
                }
            }
            
            //Modification Date
            if CGPDFDictionaryGetString(infoDict, "ModDate", &string) {
                if let aModDate = convertCFDateTypeToNSDate(CGPDFStringCopyDate(string)) {
                    modificationDate = aModDate
                }
            }
            
            //Version
            var majorVersion: Int32 = 0
            var minorVersion: Int32 = 0
            CGPDFDocumentGetVersion(thePDFDocRef, &majorVersion, &minorVersion)
            let versionString: String = "\(majorVersion).\(minorVersion)"
            version = (versionString as NSString).floatValue
            
            //Page Count
            pageCount = UInt(CGPDFDocumentGetNumberOfPages(thePDFDocRef))
            
            //File Size
            let fileAttributes: NSDictionary? = NSFileManager.defaultManager().attributesOfItemAtPath(fileURL.path!, error: nil)
            if let fileAttributes = fileAttributes {
                fileSize = fileAttributes.fileSize()
            }
            
        } else {
            //This shouldn't happen
            assert(false, "CGPDFDocumentRef == nil")
        }
    }
    
    /**
    Converts a unmanaged CFString to a String object.
    
    @param cfValue The unmanaged CFString
    
    @return A string object.
    */
    private func convertCFSStringTypeToString(cfValue: Unmanaged<CFString>!) -> String?{
        let value = Unmanaged.fromOpaque(cfValue.toOpaque()).takeUnretainedValue() as CFStringRef
        if CFGetTypeID(value) == CFStringGetTypeID() {
            return value as String
        }
        return nil
    }
    
    /**
    Converts a unmanaged CFDate to a NSDate object.
    
    @param cfValue The unmanaged CFDate
    
    @return A NSDate object.
    */
    private func convertCFDateTypeToNSDate(cfValue: Unmanaged<CFDate>!) -> NSDate? {
        let value = Unmanaged.fromOpaque(cfValue.toOpaque()).takeUnretainedValue() as CFDateRef
        if CFGetTypeID(value) == CFDateGetTypeID() {
            return value as NSDate
        }
        return nil
    }
    
    /**
    Checks to see if the file is a PDF.
    */
    private class func isPDF(filePath: String) -> Bool {
        var state = false
        
        //Does the file exist?
        if !NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            return false
        }
        
        //TODO
        //Is there a better way to do this with NSFileHandle?
        let path: [CChar] = filePath.fileSystemRepresentation()
        let fd: CInt = open(path, O_RDONLY)
        if fd > 0 {
            var sig: [CChar] = [CChar](count: 1024, repeatedValue: "0".cStringUsingEncoding(NSASCIIStringEncoding)[0])
            var len = read(fd, &sig, sizeof(CChar) * sig.count)
            state = strnstr(sig, "%PDF", len) != nil
            close(fd)
        }
        
        return state
    }
    
    //------------------------------------------
    /// @name Saving
    //------------------------------------------
    
    /**
    Save the document information to the archive.
    
    @return Returns true if the save was successful.
    */
    public func saveDocument() -> Bool {
        if let path = fileURL.path {
            return archiveWithFileAtPath(path)
        }
        return false
    }
    
    /**
    Saves the document
    
    @param path The path to archive to.
    
    @return Whether or not the save was successful.
    */
    private func archiveWithFileAtPath(path: String) -> Bool {
        let archiveFilePath: String? = PDFKDocument.archiveFilePathForFileAtPath(path)
        if let archiveFilePath = archiveFilePath {
            return NSKeyedArchiver.archiveRootObject(self, toFile: archiveFilePath)
        }
        return false
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(guid, forKey: "FileGUID")
        aCoder.encodeInteger(Int(currentPage), forKey: "CurrentPage")
        aCoder.encodeObject(bookmarks, forKey: "Bookmarks")
        aCoder.encodeObject(lastOpenedDate, forKey: "LastOpen")
        aCoder.encodeObject(fileURL, forKey: "URL")
    }
    
    /**
    Create the path for the archived data coresponding to the given file.
    
    @param filePath The path to the PDF file.
    
    @return The path to the archive for the PDF.
    */
    private class func archiveFilePathForFileAtPath(filePath: String) -> String? {
        let archivePath: String? = PDFKDocument.applicationSupportPath() // Application's "~/Library/Application Support" path
        if let archivePath = archivePath {
            let archiveName: String = PDFKDocument.sha256(filePath)!.stringByAppendingPathExtension("plist")!
            return archivePath.stringByAppendingPathComponent(archiveName)
        }
        return nil;
    }
    
    private class func applicationSupportPath() -> String? {
        //Path to the application's "~/Library/Application Support" directory
        let pathURL: NSURL? = NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: true, error: nil)
        return pathURL?.path
    }
    
    /**
    Hashes a given string using SHA256.
    
    @param input The string to hash.
    
    @return The hash of the given string.
    */
    private class func sha256(input: String) -> String? {
        let str = input.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_SHA256_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_SHA256(str!, strLen, result)
        
        var hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.dealloc(digestLen)
        
        return String(format: hash as String)
    }
    
    
}
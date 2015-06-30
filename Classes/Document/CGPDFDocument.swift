//
//  CGPDFDocument.swift
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
import QuartzCore

/**
Create a CGPDFDocumentRef from the PDF file at the given URL.

@param url      The URL of the PDF file to load.
@param password The password to unlock the file if necessary.

@return A CGPDFDocumentRef.
*/
internal func CGPDFDocumentCreate(url: NSURL, password: String?) -> CGPDFDocumentRef? {
    var docRef: CGPDFDocumentRef?
    
    docRef = CGPDFDocumentCreateWithURL(url as CFURLRef)
    
    //Did the document load?
    if let docRef = docRef {
        
        //Is the document password protected?
        if CGPDFDocumentIsEncrypted(docRef) == true {
            
            //Try a blank password first, per Apple's Quartz PDF example
            if CGPDFDocumentUnlockWithPassword(docRef, "") == false {
                
                //Nope, now let's try the provided password to unlock the PDF
                if let password = password {
                    var text: [CChar] = [] // char array buffer for the string conversion
                    password.getCString(&text, maxLength: 126, encoding: NSUTF8StringEncoding)
                    
                    //If we can't unlock the document, log failure/
                    if !CGPDFDocumentUnlockWithPassword(docRef, text) {
                        #if DEBUG
                            println("CGPDFDocumentCreate: Unable to unlock [\(url)] with [\(password)]")
                        #endif
                    }
                }
            }
            
            //If we failed to unlock the document, cleanup
            if CGPDFDocumentIsUnlocked(docRef) == false {
                //No longer needed in Swift?
                //CGPDFDocumentRelease(docRef), docRef = NULL;
            }
        }
    } else {
        #if DEBUG
            //Double check that the file exists
            var error: NSError?
            if url.checkPromisedItemIsReachableAndReturnError(&error) {
                println("CGPDFDocumentCreate: Unable to load PDF Document. It seems to be corrupted.")
            } else {
                println("CGPDFDocumentCreate: Unable to load PDF Document. \(error?.localizedDescription)")
            }
        #endif
    }
    
    return docRef
}


/**
Wether or not the given password will unlock the PDF file at the given URL.

@param url      The URL of the PDF file to check.
@param password The password to attempt to unlock the PDF file with.

@return YES if the password unlocks the document. NO otherwise.
*/
internal func CGPDFDocumentCanBeUnlockedWithPassword(url: NSURL, password: String?) -> Bool {
    var unlockable: Bool = false
    
    var docRef = CGPDFDocumentCreateWithURL(url as CFURLRef)
    
    //Did the document load?
    if let docRef = docRef {
        
        //Is the document locked?
        if CGPDFDocumentIsEncrypted(docRef) {
            
            //Try a blank password first, per Apple's Quartz PDF example
            if CGPDFDocumentUnlockWithPassword(docRef, "") == false {
                
                //Nope, now let's try the provided password to unlock the PDF
                if let password = password {
                    var text: [CChar] = [] // char array buffer for the string conversion
                    password.getCString(&text, maxLength: 126, encoding: NSUTF8StringEncoding)
                    
                    //Can we unlock it?
                    if CGPDFDocumentUnlockWithPassword(docRef, text) {
                        unlockable = true
                    }
                }
            }
        }
    }
    
    //No need to cleanup the docRef in swift?
    //CGPDFDocumentRelease(docRef)
    
    return unlockable
}

class CGPDFDocumentCreator: NSObject {
    /**
    Create a CGPDFDocumentRef from the PDF file at the given URL.
    
    @param url      The URL of the PDF file to load.
    @param password The password to unlock the file if necessary.
    
    @return A CGPDFDocumentRef.
    */
    internal class func CGPDFDocumentCreate(url: NSURL, password: String?) -> CGPDFDocumentRef? {
        var docRef: CGPDFDocumentRef?
        
        docRef = CGPDFDocumentCreateWithURL(url as CFURLRef)
        
        //Did the document load?
        if let docRef = docRef {
            
            //Is the document password protected?
            if CGPDFDocumentIsEncrypted(docRef) == true {
                
                //Try a blank password first, per Apple's Quartz PDF example
                if CGPDFDocumentUnlockWithPassword(docRef, "") == false {
                    
                    //Nope, now let's try the provided password to unlock the PDF
                    if let password = password {
                        var text: [CChar] = [] // char array buffer for the string conversion
                        password.getCString(&text, maxLength: 126, encoding: NSUTF8StringEncoding)
                        
                        //If we can't unlock the document, log failure/
                        if !CGPDFDocumentUnlockWithPassword(docRef, text) {
                            #if DEBUG
                                println("CGPDFDocumentCreate: Unable to unlock [\(url)] with [\(password)]")
                            #endif
                        }
                    }
                }
                
                //If we failed to unlock the document, cleanup
                if CGPDFDocumentIsUnlocked(docRef) == false {
                    //No longer needed in Swift?
                    //CGPDFDocumentRelease(docRef), docRef = NULL;
                }
            }
        } else {
            #if DEBUG
                //Double check that the file exists
                var error: NSError?
                if url.checkPromisedItemIsReachableAndReturnError(&error) {
                println("CGPDFDocumentCreate: Unable to load PDF Document. It seems to be corrupted.")
                } else {
                println("CGPDFDocumentCreate: Unable to load PDF Document. \(error?.localizedDescription)")
                }
            #endif
        }
        
        return docRef
    }
    
    
    /**
    Wether or not the given password will unlock the PDF file at the given URL.
    
    @param url      The URL of the PDF file to check.
    @param password The password to attempt to unlock the PDF file with.
    
    @return YES if the password unlocks the document. NO otherwise.
    */
    internal class func CGPDFDocumentCanBeUnlockedWithPassword(url: NSURL, password: String?) -> Bool {
        var unlockable: Bool = false
        
        var docRef = CGPDFDocumentCreateWithURL(url as CFURLRef)
        
        //Did the document load?
        if let docRef = docRef {
            
            //Is the document locked?
            if CGPDFDocumentIsEncrypted(docRef) {
                
                //Try a blank password first, per Apple's Quartz PDF example
                if CGPDFDocumentUnlockWithPassword(docRef, "") == false {
                    
                    //Nope, now let's try the provided password to unlock the PDF
                    if let password = password {
                        var text: [CChar] = [] // char array buffer for the string conversion
                        password.getCString(&text, maxLength: 126, encoding: NSUTF8StringEncoding)
                        
                        //Can we unlock it?
                        if CGPDFDocumentUnlockWithPassword(docRef, text) {
                            unlockable = true
                        }
                    }
                }
            }
        }
        
        //No need to cleanup the docRef in swift?
        //CGPDFDocumentRelease(docRef)
        
        return unlockable
    }

}
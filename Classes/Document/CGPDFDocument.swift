//
//  CGPDFDocument.swift
//  M13PDFKit
//
//  Created by Brandon McQuilkin on 6/26/15.
//  Copyright (c) 2015 BrandonMcQuilkin. All rights reserved.
//

import Foundation
import QuartzCore

/**
Create a CGPDFDocumentRef from the PDF file at the given URL.

@param url      The URL of the PDF file to load.
@param password The password to unlock the file if necessary.

@return A CGPDFDocumentRef.
*/
func CGPDFDocumentCreateSwift(url: NSURL, password: String?) -> CGPDFDocumentRef? {
    var docRef: CGPDFDocumentRef?
    
    docRef = CGPDFDocumentCreateWithURL(url as CFURLRef)
    
    //Did the document load?
    if let docRef = docRef {
      
      //If the document is not password protected, just return the ref
      if !CGPDFDocumentIsEncrypted(docRef){
        return docRef
      }
      
      //If the document is unlockable with an empty pass, just return the ref
      if CGPDFDocumentUnlockWithPassword(docRef, "") {
        return docRef
      }
      
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

@return true if the password unlocks the document. false otherwise.
*/
func CGPDFDocumentCanBeUnlockedWithPasswordSwift(url: NSURL, password: String?) -> Bool {
    var unlockable: Bool = false
    
    var docRef = CGPDFDocumentCreateWithURL(url as CFURLRef)
    
    //Did the document load?
    if let docRef = docRef {
        
      //Is the document unlocked?
      if !CGPDFDocumentIsEncrypted(docRef) {
        return unlockable
      }
      //Is the document unlockable with a blank password first, per Apple's Quartz PDF example
      if CGPDFDocumentUnlockWithPassword(docRef, "") {
        return unlockable
      }
      
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

    //No need to cleanup the docRef in swift?
    //CGPDFDocumentRelease(docRef)

    return unlockable
}
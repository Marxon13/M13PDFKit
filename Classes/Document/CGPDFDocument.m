//
//	CGPDFDocument.m
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

#import "CGPDFDocument.h"

CGPDFDocumentRef CGPDFDocumentCreate(NSURL *url, NSString *password)
{
	CGPDFDocumentRef docRef = NULL;
    
    //Do we have a URL?
	if (url != nil) {
		docRef = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
        
        //Did the document load?
		if (docRef != NULL) {
            
            //Is the document password protected?
			if (CGPDFDocumentIsEncrypted(docRef) == TRUE) {
                
				//Try a blank password first, per Apple's Quartz PDF example.
				if (CGPDFDocumentUnlockWithPassword(docRef, "") == FALSE) {
                    
					//Nope, now let's try the provided password to unlock the PDF
					if ((password != nil) && ([password length] > 0)) {
                        
						char text[128]; // char array buffer for the string conversion
						[password getCString:text maxLength:126 encoding:NSUTF8StringEncoding];
                        
                        //If we can't unlock the document.
						if (CGPDFDocumentUnlockWithPassword(docRef, text) == FALSE) // Log failure
						{
                            #ifdef DEBUG
                            NSLog(@"CGPDFDocumentCreate: Unable to unlock [%@] with [%@]", url, password);
                            #endif
						}
					}
				}
                //Failed to unlock the document. Cleanup.
				if (CGPDFDocumentIsUnlocked(docRef) == FALSE) {
					CGPDFDocumentRelease(docRef), docRef = NULL;
				}
			}
		} else {
            #ifdef DEBUG
            
            //Double check that the file exists
            NSError *error;
            BOOL urlExists = [url checkResourceIsReachableAndReturnError:&error];
            if (urlExists) {
                NSLog(@"CGPDFDocumentCreate: Unable to load PDF Document. It seems to be corrupted.");
            } else {
                NSLog(@"CGPDFDocumentCreate: Unable to load PDF Document. %@", error.localizedDescription);
            }
            
            #endif
        }
	} else {
        #ifdef DEBUG
        NSLog(@"CGPDFDocumentCreate: No URL Provided");
        #endif
	}
    
	return docRef;
}

BOOL CGPDFDocumentCanBeUnlockedWithPassword(NSURL *url, NSString *password)
{
	BOOL unlockable = NO;
    //Do we have a URL
	if (url != nil) {
		CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
        
        //Do we have a document?
		if (thePDFDocRef != NULL)
		{
            //Is the document locked?
			if (CGPDFDocumentIsEncrypted(thePDFDocRef) == TRUE) {
                
				// Try a blank password first, per Apple's Quartz PDF example
				if (CGPDFDocumentUnlockWithPassword(thePDFDocRef, "") == FALSE) {
                    
					// Nope, now let's try the provided password to unlock the PDF
					if ((password != nil) && ([password length] > 0)) // Not blank?
					{
						char text[128]; // char array buffer for the string conversion
                        
						[password getCString:text maxLength:126 encoding:NSUTF8StringEncoding];
                        
						if (CGPDFDocumentUnlockWithPassword(thePDFDocRef, text) == FALSE) {
							unlockable = YES;
						}
					} else {
						unlockable = NO;
					}
				}
			}
            
			CGPDFDocumentRelease(thePDFDocRef); // Cleanup CGPDFDocumentRef
		}
	} else {
        #ifdef DEBUG
        NSLog(@"CGPDFDocumentCanBeUnlockedWithPassword: No URL Provided");
        #endif
	}
    
	return unlockable;
}

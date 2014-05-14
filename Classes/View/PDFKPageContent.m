//
//	ReaderContentPage.m
//	Reader v2.7.3
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

#import "PDFKPageContent.h"
#import "PDFKPageContentLayer.h"
#import "CGPDFDocument.h"

@implementation PDFKPageContent
{
	/**
	 The document links in the page.
	 */
	NSMutableArray *_links;
	/**
	 The refrence to the document.
	 */
	CGPDFDocumentRef _PDFDocRef;
	/**
	 The refrence to the document page.
	 */
	CGPDFPageRef _PDFPageRef;
	/**
	 The angle of the page (0, 90, 180, 270)
	 */
	NSInteger _pageAngle;
	/**
	 The size of the page.
	 */
	CGFloat _pageWidth;
	CGFloat _pageHeight;
	/**
	 The page offset.
	 */
	CGFloat _pageOffsetX;
	CGFloat _pageOffsetY;
    
    NSInteger _page;
}

+ (Class)layerClass
{
    //Override the base layer class
	return [PDFKPageContentLayer class];
}

- (void)highlightPageLinks
{
	if (_links.count > 0) // Add highlight views over all links
	{
		UIColor *hilite = [self tintColor];
        if (!hilite) {
            hilite = [UIColor colorWithRed:0.11 green:0.5 blue:0.95 alpha:1];
        }
        
		for (PDFKDocumentLink *link in _links) {
            
			UIView *highlight = [[UIView alloc] initWithFrame:link.rect];
            
			highlight.autoresizesSubviews = NO;
			highlight.userInteractionEnabled = NO;
			highlight.contentMode = UIViewContentModeRedraw;
			highlight.autoresizingMask = UIViewAutoresizingNone;
			highlight.backgroundColor = hilite; // Color
            
			[self addSubview:highlight];
		}
	}
}

- (PDFKDocumentLink *)linkFromAnnotation:(CGPDFDictionaryRef)annotationDictionary
{
	PDFKDocumentLink *documentLink = nil;
    // Annotation co-ordinates array
	CGPDFArrayRef annotationRectArray = NULL;
    
    //If we can get the annotation's location and size, we need to convert that from PDF coordinates to view coordinates
	if (CGPDFDictionaryGetArray(annotationDictionary, "Rect", &annotationRectArray)) {
        //PDFRect lower-left X and Y
		CGPDFReal ll_x = 0.0f;
        CGPDFReal ll_y = 0.0f;
        //PDFRect upper-right X and Y
		CGPDFReal ur_x = 0.0f;
        CGPDFReal ur_y = 0.0f;
        
        //Lower-left
		CGPDFArrayGetNumber(annotationRectArray, 0, &ll_x);
		CGPDFArrayGetNumber(annotationRectArray, 1, &ll_y);
        //Upper-right
		CGPDFArrayGetNumber(annotationRectArray, 2, &ur_x);
		CGPDFArrayGetNumber(annotationRectArray, 3, &ur_y);
        
        //Normalize
		if (ll_x > ur_x) {
            CGPDFReal t = ll_x;
            ll_x = ur_x;
            ur_x = t;
        }
		if (ll_y > ur_y) {
            CGPDFReal t = ll_y;
            ll_y = ur_y;
            ur_y = t;
        }
        
        //Offset
		ll_x -= _pageOffsetX;
        ll_y -= _pageOffsetY;
		ur_x -= _pageOffsetX;
        ur_y -= _pageOffsetY;
        
        //Page rotation angle (in degrees)
		switch (_pageAngle) {
			case 90: {
				CGPDFReal swap;
				swap = ll_y;
                ll_y = ll_x;
                ll_x = swap;
				swap = ur_y;
                ur_y = ur_x;
                ur_x = swap;
				break;
			}
			case 270: {
				CGPDFReal swap;
				swap = ll_y;
                ll_y = ll_x;
                ll_x = swap;
				swap = ur_y;
                ur_y = ur_x;
                ur_x = swap;
				ll_x = ((0.0f - ll_x) + _pageWidth);
				ur_x = ((0.0f - ur_x) + _pageWidth);
				break;
			}
			case 0: {
				ll_y = ((0.0f - ll_y) + _pageHeight);
				ur_y = ((0.0f - ur_y) + _pageHeight);
				break;
			}
		}
        
        //Integer X and width
		NSInteger vr_x = ll_x;
        NSInteger vr_w = (ur_x - ll_x);
        
        //Integer Y and height
		NSInteger vr_y = ll_y;
        NSInteger vr_h = (ur_y - ll_y);
        
        //View CGRect from PDFRect
		CGRect viewRect = CGRectMake(vr_x, vr_y, vr_w, vr_h);
        
		documentLink = [PDFKDocumentLink newWithRect:viewRect dictionary:annotationDictionary];
	}
    
	return documentLink;
}

- (void)buildAnnotationLinksList
{
	_links = [NSMutableArray new];
	CGPDFArrayRef pageAnnotations = NULL;
    
    //Get the dictionary of the page.
	CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(_PDFPageRef);
    //Get the annotations of the page.
	if (CGPDFDictionaryGetArray(pageDictionary, "Annots", &pageAnnotations) == true) {
        
        //Number of annotations
		NSInteger count = CGPDFArrayGetCount(pageAnnotations);
        
        
		for (NSInteger index = 0; index < count; index++) {
            
            CGPDFDictionaryRef annotationDictionary = NULL;
			if (CGPDFArrayGetDictionary(pageAnnotations, index, &annotationDictionary) == true) {
                
                //PDF annotation subtype string
				const char *annotationSubtype = NULL;
                
				if (CGPDFDictionaryGetName(annotationDictionary, "Subtype", &annotationSubtype) == true) {
                    //Found annotation subtype of 'Link'
					if (strcmp(annotationSubtype, "Link") == 0) {
                        //Create and add the link to the list.
						PDFKDocumentLink *documentLink = [self linkFromAnnotation:annotationDictionary];
						if (documentLink != nil) {
                            [_links insertObject:documentLink atIndex:0];
                        }
					}
				}
			}
		}
        
        #if DEBUG
		//[self highlightPageLinks]; // Link support debugging
        #endif
	}
}

- (CGPDFArrayRef)destinationWithName:(const char *)destinationName inDestsTree:(CGPDFDictionaryRef)node
{
	CGPDFArrayRef destinationArray = NULL;
	CGPDFArrayRef limitsArray = NULL;
    
    //Check to see if we are outside the node's limits
	if (CGPDFDictionaryGetArray(node, "Limits", &limitsArray) == true) {
        
		CGPDFStringRef lowerLimit = NULL;
        CGPDFStringRef upperLimit = NULL;
        
        //Get the lower and upper limits
		if (CGPDFArrayGetString(limitsArray, 0, &lowerLimit) == true) {
			if (CGPDFArrayGetString(limitsArray, 1, &upperLimit) == true) {
                
				const char *ll = (const char *)CGPDFStringGetBytePtr(lowerLimit);
				const char *ul = (const char *)CGPDFStringGetBytePtr(upperLimit);
                
				if ((strcmp(destinationName, ll) < 0) || (strcmp(destinationName, ul) > 0)) {
					return NULL; // Destination name is outside this node's limits
				}
			}
		}
	}
    
    //Check to see if we have a name's array.
	CGPDFArrayRef namesArray = NULL;
	if (CGPDFDictionaryGetArray(node, "Names", &namesArray) == true) {
        
		NSInteger namesCount = CGPDFArrayGetCount(namesArray);
        
		for (NSInteger index = 0; index < namesCount; index += 2) {
            
            //Destination name string
			CGPDFStringRef destName;
            
			if (CGPDFArrayGetString(namesArray, index, &destName) == true) {
                
				const char *dn = (const char *)CGPDFStringGetBytePtr(destName);
                
                //Found the destination name
				if (strcmp(dn, destinationName) == 0) {
					if (CGPDFArrayGetArray(namesArray, (index + 1), &destinationArray) == false) {
                        
						CGPDFDictionaryRef destinationDictionary = NULL;
                        
						if (CGPDFArrayGetDictionary(namesArray, (index + 1), &destinationDictionary) == true) {
							CGPDFDictionaryGetArray(destinationDictionary, "D", &destinationArray);
						}
					}
                    //We have a destination array
					return destinationArray;
				}
			}
		}
	}
    
    //Check to see if we have a kids array
	CGPDFArrayRef kidsArray = NULL;
	if (CGPDFDictionaryGetArray(node, "Kids", &kidsArray) == true) {
        
		NSInteger kidsCount = CGPDFArrayGetCount(kidsArray);
        
		for (NSInteger index = 0; index < kidsCount; index++) {
            
			CGPDFDictionaryRef kidNode = NULL;
            //Recurse into node
			if (CGPDFArrayGetDictionary(kidsArray, index, &kidNode) == true) {
				destinationArray = [self destinationWithName:destinationName inDestsTree:kidNode];
				if (destinationArray != NULL) {
                    return destinationArray; // Return destination array
                }
			}
		}
	}
    
    //We got nothing.
	return NULL;
}

- (id)annotationLinkTarget:(CGPDFDictionaryRef)annotationDictionary
{
	id linkTarget = nil;
	CGPDFStringRef destName = NULL;
    const char *destString = NULL;
	CGPDFDictionaryRef actionDictionary = NULL;
    CGPDFArrayRef destArray = NULL;
    
	if (CGPDFDictionaryGetDictionary(annotationDictionary, "A", &actionDictionary) == true) {
        
        //Annotation action type string
		const char *actionType = NULL;
        
		if (CGPDFDictionaryGetName(actionDictionary, "S", &actionType) == true) {
            
            //GoTo action type
			if (strcmp(actionType, "GoTo") == 0) {
				if (CGPDFDictionaryGetArray(actionDictionary, "D", &destArray) == false) {
					CGPDFDictionaryGetString(actionDictionary, "D", &destName);
				}
                
			} else  {
                //Handle other link action type possibility
                
                //URI action type
				if (strcmp(actionType, "URI") == 0) {
                    
					CGPDFStringRef uriString = NULL;
					if (CGPDFDictionaryGetString(actionDictionary, "URI", &uriString) == true) {
                        //Destination URI string
						const char *uri = (const char *)CGPDFStringGetBytePtr(uriString);
                        NSString *target = [NSString stringWithCString:uri encoding:NSUTF8StringEncoding];
                        linkTarget = [NSURL URLWithString:[target stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                        //Debug check
                        #if DEBUG
						if (linkTarget == nil) NSLog(@"%s Bad URI '%@'", __FUNCTION__, target);
                        #endif
					}
				}
			}
		}
	} else {
        // Handle other link target possibilities
		if (CGPDFDictionaryGetArray(annotationDictionary, "Dest", &destArray) == false) {
			if (CGPDFDictionaryGetString(annotationDictionary, "Dest", &destName) == false) {
				CGPDFDictionaryGetName(annotationDictionary, "Dest", &destString);
			}
		}
	}
    
    //Handle a destination name
	if (destName != NULL) {
		CGPDFDictionaryRef catalogDictionary = CGPDFDocumentGetCatalog(_PDFDocRef);
		CGPDFDictionaryRef namesDictionary = NULL;
        
		if (CGPDFDictionaryGetDictionary(catalogDictionary, "Names", &namesDictionary) == true) {
            
			CGPDFDictionaryRef destsDictionary = NULL;
            
			if (CGPDFDictionaryGetDictionary(namesDictionary, "Dests", &destsDictionary) == true) {
				const char *destinationName = (const char *)CGPDFStringGetBytePtr(destName);
				destArray = [self destinationWithName:destinationName inDestsTree:destsDictionary];
			}
		}
	}
    
    //Handle a destination string
	if (destString != NULL) {
		CGPDFDictionaryRef catalogDictionary = CGPDFDocumentGetCatalog(_PDFDocRef);
		CGPDFDictionaryRef destsDictionary = NULL;
        
		if (CGPDFDictionaryGetDictionary(catalogDictionary, "Dests", &destsDictionary) == true) {
            
			CGPDFDictionaryRef targetDictionary = NULL;
			if (CGPDFDictionaryGetDictionary(destsDictionary, destString, &targetDictionary) == true) {
				CGPDFDictionaryGetArray(targetDictionary, "D", &destArray);
			}
		}
	}
    
    //Handle a destination array
	if (destArray != NULL) {
		NSInteger targetPageNumber = 0;
		CGPDFDictionaryRef pageDictionaryFromDestArray = NULL;
        
		if (CGPDFArrayGetDictionary(destArray, 0, &pageDictionaryFromDestArray) == true) {
            
			NSInteger pageCount = CGPDFDocumentGetNumberOfPages(_PDFDocRef);
			for (NSInteger pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
                
				CGPDFPageRef pageRef = CGPDFDocumentGetPage(_PDFDocRef, pageNumber);
				CGPDFDictionaryRef pageDictionaryFromPage = CGPDFPageGetDictionary(pageRef);
                
                //Found it!
				if (pageDictionaryFromPage == pageDictionaryFromDestArray) {
					targetPageNumber = pageNumber; break;
				}
			}
		} else {
            //Try page number from array possibility
			CGPDFInteger pageNumber = 0;
            
			if (CGPDFArrayGetInteger(destArray, 0, &pageNumber) == true) {
				targetPageNumber = (pageNumber + 1); // 1-based
			}
		}
        
        //We have a target page number
		if (targetPageNumber > 0) {
			linkTarget = [NSNumber numberWithInteger:targetPageNumber];
		}
	}
    
	return linkTarget;
}

- (id)processSingleTap:(UITapGestureRecognizer *)recognizer
{
	id result = nil; // Tap result object
    
	if (recognizer.state == UIGestureRecognizerStateRecognized) {
		if (_links.count > 0) {
            
			CGPoint point = [recognizer locationInView:self];
            
            //Search for a link at that point
			for (PDFKDocumentLink *link in _links) {
				if (CGRectContainsPoint(link.rect, point) == true) {
					result = [self annotationLinkTarget:link.dictionary];
                    break;
				}
			}
		}
	}
    
	return result;
}

- (id)initWithFrame:(CGRect)frame
{
    //Don't want to return an empty view.
	id view = nil;
    
	if (CGRectIsEmpty(frame) == false) {
		if ((self = [super initWithFrame:frame])) {
            
			self.autoresizesSubviews = NO;
			self.userInteractionEnabled = NO;
			self.contentMode = UIViewContentModeRedraw;
			self.autoresizingMask = UIViewAutoresizingNone;
			self.backgroundColor = [UIColor clearColor];
            
			view = self;
		}
	} else {
		self = nil;
	}
    
	return view;
}

- (id)initWithURL:(NSURL *)fileURL page:(NSInteger)page password:(NSString *)phrase
{
	CGRect viewRect = CGRectZero;
    
	if (fileURL != nil) {
        
		_PDFDocRef = CGPDFDocumentCreate(fileURL, phrase);
        
		if (_PDFDocRef != NULL) {
			if (page < 1) page = 1; // Check the lower page bounds
            
			NSInteger pages = CGPDFDocumentGetNumberOfPages(_PDFDocRef);
            
			if (page > pages) page = pages; // Check the upper page bounds
            
			_PDFPageRef = CGPDFDocumentGetPage(_PDFDocRef, page); // Get page
            
			if (_PDFPageRef != NULL) {
                
                _page = page;
                
				CGPDFPageRetain(_PDFPageRef); // Retain the PDF page
                
				CGRect cropBoxRect = CGPDFPageGetBoxRect(_PDFPageRef, kCGPDFCropBox);
				CGRect mediaBoxRect = CGPDFPageGetBoxRect(_PDFPageRef, kCGPDFMediaBox);
				CGRect effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect);
                
				_pageAngle = CGPDFPageGetRotationAngle(_PDFPageRef);
                
				switch (_pageAngle)
				{
					default:
					case 0: case 180: {
						_pageWidth = effectiveRect.size.width;
						_pageHeight = effectiveRect.size.height;
						_pageOffsetX = effectiveRect.origin.x;
						_pageOffsetY = effectiveRect.origin.y;
						break;
					}
                        
					case 90: case 270: {
						_pageWidth = effectiveRect.size.height;
						_pageHeight = effectiveRect.size.width;
						_pageOffsetX = effectiveRect.origin.y;
						_pageOffsetY = effectiveRect.origin.x;
						break;
					}
				}
                
				NSInteger page_w = _pageWidth;
				NSInteger page_h = _pageHeight;
                
                //Make even?
				if (page_w % 2) page_w--;
                if (page_h % 2) page_h--;
                
                //View size
				viewRect.size = CGSizeMake(page_w, page_h);
			} else {
				CGPDFDocumentRelease(_PDFDocRef);
                _PDFDocRef = NULL;
				NSAssert(NO, @"CGPDFPageRef == NULL");
			}
		} else {
			NSAssert(NO, @"CGPDFDocumentRef == NULL");
		}
	} else {
		NSAssert(NO, @"fileURL == nil");
	}
    
	id view = [self initWithFrame:viewRect]; // UIView setup
	if (view != nil) [self buildAnnotationLinksList]; // Links
    
	return view;
}

- (void)removeFromSuperview
{
	self.layer.delegate = nil;
	[super removeFromSuperview];
}

- (void)dealloc
{
	CGPDFPageRelease(_PDFPageRef), _PDFPageRef = NULL;
	CGPDFDocumentRelease(_PDFDocRef), _PDFDocRef = NULL;
}

#pragma mark CATiledLayer delegate methods

- (void)drawLayer:(CATiledLayer *)layer inContext:(CGContextRef)context
{
    //Retain self?
	PDFKPageContent *readerContentPage = self;
    
    //Fill self
	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextFillRect(context, CGContextGetClipBoundingBox(context));
    
    //Translate for Page
	CGContextTranslateCTM(context, 0.0f, self.bounds.size.height); CGContextScaleCTM(context, 1.0f, -1.0f);
	CGContextConcatCTM(context, CGPDFPageGetDrawingTransform(_PDFPageRef, kCGPDFCropBox, self.bounds, 0, true));
    
    //Render the PDF page into the context
	CGContextDrawPDFPage(context, _PDFPageRef);
    
    //Release self
	if (readerContentPage != nil) readerContentPage = nil;
}

@end

@implementation PDFKDocumentLink

+ (id)newWithRect:(CGRect)linkRect dictionary:(CGPDFDictionaryRef)linkDictionary
{
	return [[PDFKDocumentLink alloc] initWithRect:linkRect dictionary:linkDictionary];
}

#pragma mark ReaderDocumentLink instance methods

- (id)initWithRect:(CGRect)linkRect dictionary:(CGPDFDictionaryRef)linkDictionary
{
	if ((self = [super init])) {
		_dictionary = linkDictionary;
		_rect = linkRect;
	}
    return self;
}

@end

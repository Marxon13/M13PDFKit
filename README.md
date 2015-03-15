<img src="https://raw.github.com/Marxon13/M13PDFKit/master/ReadmeResources/M13PDFKitBanner.png">

M13PDFKit
=============
M13PDFKit is an iBooks like PDF viewer that can be embedded in iOS applications. M13PDFKit is based off of [vfr/Reader](https://github.com/vfr/Reader). The backend uses the same classes that Reader uses, the front end has been recreated to match iOS 7's design, and use more up to date features, like UICollectionViews.

Screenshots:
-------------

* Main view, with toolbars showing.

<img src="https://raw.github.com/Marxon13/M13PDFKit/master/ReadmeResources/IMG_1041.PNG" width="300px">

* Main view without toolbars.

<img src="https://raw.github.com/Marxon13/M13PDFKit/master/ReadmeResources/IMG_1042.PNG" width="300px">

* Main view, bookmarked page.

<img src="https://raw.github.com/Marxon13/M13PDFKit/master/ReadmeResources/IMG_1043.PNG" width="300px">

* Thumb list, all pages.

<img src="https://raw.github.com/Marxon13/M13PDFKit/master/ReadmeResources/IMG_1044.PNG" width="300px">

* Thumb list, bookmarked pages.

<img src="https://raw.github.com/Marxon13/M13PDFKit/master/ReadmeResources/IMG_1045.PNG" width="300px">


Installation
-------------

#### Podfile

```ruby
source 'https://github.com/CocoaPods/Specs.git'

pod 'M13PDFKit', '1.0.2'
```

Usage
-------------

*Prerequisite:* In the storyboard, the ViewController that is intended to display the PDF file needs to be in a UINavigationController stack and its corresponding class needs to be `PDFKBasicPDFViewer`

Next, in the `prepareSegue` method of your ViewController which segues to your PDF View Controller you will then need to add the following lines:

**Objective-C**
```objective-c
//Create the document for the viewer when the segue is performed.
PDFKBasicPDFViewer *viewer = (PDFKBasicPDFViewer *)segue.destinationViewController;

//Load the document
PDFKDocument *document = [PDFKDocument documentWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Your PDF document actual location" ofType:@"pdf"] password:nil];
[viewer loadDocument:document];
```

**Swift**
```swift
//Create the document for the viewer when the segue is performed.
var viewer: PDFKBasicPDFViewer = segue.destinationViewController as PDFKBasicPDFViewer

//Load the document (pdfUrl represents the path on the phone of the pdf document you wish to load)
var document: PDFKDocument = PDFKDocument(contentsOfFile: pdfUrl!, password: nil)
viewer.loadDocument(document)
```

In any case, you can see an example here in the [SamplesTableViewController](https://github.com/Marxon13/M13PDFKit/blob/master/M13PDFKit/SamplesTableViewController.m#L42) (Obj-C only)

Issues:
-------------
There are two issues I am unable to resolve with the framework, and would like help solving.

1) The viewer has trouble handling rotation. Upon rotation the page that is currently displayed on screen does not resize to the proper size. Once you switch pages though, everything is fine.

2) Zooming in on pages does not allow panning. Something is overrideing the content offset while panning, and not calling "setContentOffset:{0, 0}". The pan gesture for the scroll view send the proper content offset, but the scroll view does not pan. When you pan again, the content offset starts from 0 again. It was working, but while trying to fix rotation, this broke, and I can't figure out what is wrong.

Contact Me:
-------------
If you have any questions comments or suggestions, send me a message. If you find a bug, or want to submit a pull request, let me know.

License:
--------
MIT License

> Copyright (c) 2014 Brandon McQuilkin
> 
> Permission is hereby granted, free of charge, to any person obtaining 
>a copy of this software and associated documentation files (the  
>"Software"), to deal in the Software without restriction, including 
>without limitation the rights to use, copy, modify, merge, publish, 
>distribute, sublicense, and/or sell copies of the Software, and to 
>permit persons to whom the Software is furnished to do so, subject to  
>the following conditions:
> 
> The above copyright notice and this permission notice shall be 
>included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
>EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
>MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
>IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
>CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
>TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
>SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
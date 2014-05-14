# TTOpenInAppActivity

`TTOpenInAppActivity` is a `UIActivity` subclass that provides an "Open In ..." action to a `UIActivityViewController`. `TTOpenInAppActivity` uses an UIDocumentInteractionController to present all Apps than can handle the document specified with by the activity items.

<img src=http://i40.tinypic.com/xn887b.png width="320px" />

## Used In

- [Stud.IP Mobile by Tobias Tiemerding](http://www.studip-mobile.de)
- [PenUltimate by Evernote](https://itunes.apple.com/app/penultimate/id354098826?mt=8)
- [Bugshot by Marco Arment](https://itunes.apple.com/de/app/bugshot/id669858907?mt=8)
- [WriteDown - a Markdown text editor with syncing support by Nguyen Vinh](https://itunes.apple.com/app/id670733152)
- [Trail Maker](https://itunes.apple.com/de/app/trail-maker/id651198801?l=en&mt=8)
- [Syncspace by The Infinite Kind](http://infinitekind.com/syncspace)
- [SketchTo by The Infinite Kind](http://infinitekind.com/sketchto)
- [Calex by Martin Stemmle](http://calexapp.com)
- Please tell me if you use TTOpenInAppActivity in your App (just submit it as an [issue](https://github.com/honkmaster/TTOpenInAppActivity/issues))! 

## Requirements

- As `UIActivity` is iOS 6 only, so is the subclass.
- This project uses ARC. If you want to use it in a non ARC project, you must add the `-fobjc-arc` compiler flag to TTOpenInAppActivity.m in Target Settings > Build Phases > Compile Sources.

## Installation

Add the `TTOpenInAppActivity` subfolder to your project. There are no required libraries other than `UIKit` and `MobileCoreServices`.

## Usage.

- We keep a weak referemce to the superview (UIActionSheet). In this way we dismiss the UIActionSheet ans instead display the UIDocumentInterActionController.
- `TTOpenInAppActivity` needs to be initalized with the current view (iPhone & iPad) and a) a CGRect or b) a UIBarButtonItem (both only for iPad) from where it can present the UIDocumentInterActionController.
- See example project.

```objectivec
NSURL *URL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"empty" ofType:@"pdf"]];
TTOpenInAppActivity *openInAppActivity = [[TTOpenInAppActivity alloc] initWithView:self.view andRect:((UIButton *)sender).frame];
UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:@[openInAppActivity]];
    
if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
    // Store reference to superview (UIActionSheet) to allow dismissal
    openInAppActivity.superViewController = activityViewController;
    // Show UIActivityViewController 
    [self presentViewController:activityViewController animated:YES completion:NULL];
} else {
    // Create pop up
    self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
    // Store reference to superview (UIPopoverController) to allow dismissal
    openInAppActivity.superViewController = self.activityPopoverController;
    // Show UIActivityViewController in popup
    [self.activityPopoverController presentPopoverFromRect:((UIButton *)sender).frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

```
## License

Copyright (c) 2012-2013 Tobias Tiemerding

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



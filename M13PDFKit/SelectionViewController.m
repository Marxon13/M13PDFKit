//
//  SelectionViewController.m
//  M13PDFKit
//
//  Created by Brandon McQuilkin on 5/5/14.
//  Copyright (c) 2014 Brandon McQuilkin. All rights reserved.
//

#import "SelectionViewController.h"
#import "PDFKBasicPDFViewer.h"
#import "PDFKDocument.h"

@interface SelectionViewController ()

@end

@implementation SelectionViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"BasicViewerSegue"]) {
        PDFKBasicPDFViewer *viewer = (PDFKBasicPDFViewer *)segue.destinationViewController;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Wikipedia" ofType:@"pdf"];
        PDFKDocument *document = [PDFKDocument documentWithContentsOfFile:path password:nil];
        [viewer loadDocument:document];
    }
}


@end

//
//  SamplesTableViewController.m
//  M13PDFKit
//
//  Created by Brandon McQuilkin on 11/20/14.
//  Copyright (c) 2014 BrandonMcQuilkin. All rights reserved.
//

#import "SamplesTableViewController.h"
#import "PDFKBasicPDFViewer.h"
#import "PDFKDocument.h"


@interface SamplesTableViewController ()

@end

@implementation SamplesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"Basic Sample"]) {
        //Create the document for the viewer when the segue is performed.
        PDFKBasicPDFViewer *viewer = (PDFKBasicPDFViewer *)segue.destinationViewController;
        PDFKDocument *document = [PDFKDocument documentWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Wikipedia" ofType:@"pdf"] password:nil];
        [viewer loadDocument:document];
    }
}


@end

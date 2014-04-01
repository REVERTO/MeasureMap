//
//  MMLicenseViewContoller.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2013/03/09.
//  Copyright (c) 2013年 REVERTO. All rights reserved.
//

#import "MMLicenseViewContoller.h"

@interface MMLicenseViewContoller ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;

- (IBAction)closeButtonDidTap:(UIBarButtonItem *)button;

@end

@implementation MMLicenseViewContoller

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Change button label.
    _closeButton.title = NSLocalizedString(@"button.close", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"licenses" ofType:@"html"];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeButtonDidTap:(UIBarButtonItem *)button
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    if (!request.URL.isFileURL) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    return YES;
}

@end

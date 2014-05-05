//
//  MMBaseTableViewController.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 4/28/14.
//  Copyright (c) 2014 REVERTO. All rights reserved.
//

#import "MMBaseTableViewController.h"

@interface MMBaseTableViewController ()

@property UIView *overlay;
@property UIActivityIndicatorView *indicator;

@end

@implementation MMBaseTableViewController

- (IBAction)returnForSegue:(UIStoryboardSegue *)segue
{
}

- (void)showLoadingIndicator
{
    self.overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.overlay.backgroundColor = RGBA(0, 0, 0, 0.5);
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.indicator.center = CGPointMake(self.overlay.frame.size.width/2, self.overlay.frame.size.height/2);
    [self.overlay addSubview:self.indicator];
    [self.indicator startAnimating];
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [window addSubview:self.overlay];
}

- (void)hideLoadingIndicator
{
    [self.indicator stopAnimating];
    [self.indicator removeFromSuperview];
    self.indicator = nil;
    [self.overlay removeFromSuperview];
    self.overlay = nil;
}

@end

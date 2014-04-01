//
//  UIViewController+MM.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2013/03/17.
//  Copyright (c) 2013年 REVERTO. All rights reserved.
//

#import "UIViewController+MM.h"

#define ORIENTATION [[UIDevice currentDevice] orientation]

@implementation UIViewController (MM)

- (BOOL)shouldAutorotate
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return NO;
    }
    else {
        return YES;
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    else {
        return UIInterfaceOrientationMaskAll;
    }
}

@end

//
//  MMCalloutButton.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2013/03/16.
//  Copyright (c) 2013年 REVERTO. All rights reserved.
//

#import "MMCalloutButton.h"

@interface MMCalloutButton ()

@property (strong, nonatomic) UIButton *button;

@end

@implementation MMCalloutButton

+ (MMCalloutButton *)instance
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    MMCalloutButton *calloutButton = [[MMCalloutButton alloc] initWithFrame:button.bounds];
    calloutButton.button = button;
    [calloutButton addSubview:button];
    
    return calloutButton;
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    [self.button addTarget:target action:action forControlEvents:controlEvents];
}

@end

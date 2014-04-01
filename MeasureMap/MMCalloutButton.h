//
//  MMCalloutButton.h
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2013/03/16.
//  Copyright (c) 2013年 REVERTO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MMCalloutButton : UIView

@property (strong, nonatomic) MKPointAnnotation *annotation;

+ (MMCalloutButton *)instance;

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@end

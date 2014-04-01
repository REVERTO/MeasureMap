//
//  MMAppDelegate.h
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2012/11/01.
//  Copyright (c) 2012年 REVERTO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "JASidePanelController.h"
#import "MMLocationInformationViewController.h"

@interface MMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) JASidePanelController *sidePanelController;
@property (strong, nonatomic) MMLocationInformationViewController *locationInformationVC;

@end

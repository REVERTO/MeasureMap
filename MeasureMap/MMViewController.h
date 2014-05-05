//
//  MMViewController.h
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2012/11/01.
//  Copyright (c) 2012年 REVERTO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <iAd/iAd.h>
#import "GAI.h"
#import <iToast.h>

@interface MMViewController : GAITrackedViewController
<ADBannerViewDelegate, UITableViewDataSource, UITableViewDataSource,CLLocationManagerDelegate, UISplitViewControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *currentButton;

- (void)removeAdBanner;

@end

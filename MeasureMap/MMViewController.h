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

@interface MMViewController : GAITrackedViewController
<ADBannerViewDelegate, UITableViewDataSource, UITableViewDataSource,CLLocationManagerDelegate, UISplitViewControllerDelegate>

@end

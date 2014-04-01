//
//  MMListViewController.h
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2012/11/04.
//  Copyright (c) 2012年 REVERTO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAI.h"

@interface MMListViewController : GAITrackedViewController <UITableViewDelegate>

@property (weak, nonatomic) NSMutableArray *annotations;

@end

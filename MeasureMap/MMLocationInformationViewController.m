//
//  MMLocationInformationViewController.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2013/03/08.
//  Copyright (c) 2013年 REVERTO. All rights reserved.
//

#import "MMLocationInformationViewController.h"
#import "MMLicenseViewContoller.h"
#import "MMAppDelegate.h"

@interface MMLocationInformationViewController ()

@property (weak, nonatomic) IBOutlet UILabel *latitudeTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *latitudeValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *pinDeleteLabel;

@end

@implementation MMLocationInformationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _latitudeTitleLabel.text = NSLocalizedString(@"word.latitude", nil);
    _longitudeTitleLabel.text = NSLocalizedString(@"word.longitude", nil);
    _pinDeleteLabel.text = NSLocalizedString(@"message.pinDelete", nil);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGRect rect = self.view.frame;
        rect.origin.x = 60;
        rect.size.width = 260;
        self.view.frame = rect;
    }
    
    self.coordinate = _coordinate;
}

#pragma - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"word.locationInformaition", nil);
    }
    else {
          return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"deletePin" object:nil];
    }
    else if (indexPath.section == 2) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        MMLicenseViewContoller *licenseVC = [storyboard instantiateViewControllerWithIdentifier:@"MMLicenseViewContoller"];
        [self presentViewController:licenseVC animated:YES completion:nil];
    }
}

#pragma - Accessor

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    _latitudeValueLabel.text = [NSString stringWithFormat:@"%f",coordinate.latitude];
    _longitudeValueLabel.text = [NSString stringWithFormat:@"%f",coordinate.longitude];
    
    _coordinate = coordinate;
}

@end

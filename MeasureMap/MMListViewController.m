//
//  MMListViewController.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2012/11/04.
//  Copyright (c) 2012年 REVERTO. All rights reserved.
//

#import "MMListViewController.h"
#import <MapKit/MapKit.h>

@interface MMListViewController ()
{
    CLLocationDistance _totalDistance;
    NSMutableArray *_cellTexts;
}

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MMListViewController

#pragma mark - UIView Lifecycle

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
	// Do any additional setup after loading the view.
    self.screenName = NSStringFromClass([self class]);

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateAnnotations:) name:kNOUpdateAnnotations object:nil];
    
    // Change button label.
    _closeButton.title = NSLocalizedString(@"button.close", nil);
    
    [self reloadWithDistances:_distances];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.tableView.sectionHeaderHeight = 20;
    }
    else {
        self.tableView.sectionHeaderHeight = 1;
    }
}

- (void)updateAnnotations:(NSNotification *)notification
{
    NSArray *distances = [[notification userInfo] valueForKey:@"distances"];
    [self reloadWithDistances:distances];
    [_tableView reloadData];
}

- (void)reloadWithDistances:(NSArray *)distances
{
    _cellTexts = [NSMutableArray array];
    _totalDistance = 0.0;
    _navigationBar.topItem.title = @"";
    
    NSInteger fromPinNumber = 1;
    for (NSNumber *distanceValue in distances) {
        CLLocationDistance distance = distanceValue.doubleValue;
        NSMutableString *cellText = [NSMutableString stringWithFormat:@"No.%d %@ No.%d", fromPinNumber, NSLocalizedString(@"word.to", nil), (fromPinNumber + 1)];
        [_cellTexts addObject:cellText];
        
        if ([[NSUserDefaults standardUserDefaults] integerForKey:kUDDistanceUnits] == MMDistanceUnitsMeters) {
            if (distance < 1000) {
                [cellText appendFormat:@" : %.0lfm", distance];
            }
            else {
                [cellText appendFormat:@" : %.1lfkm", (distance / 1000)];
            }
        }
        else {
            [cellText appendFormat:@" : %.2lfmi", (distance / 1640)];
        }
        _totalDistance += distance;
        fromPinNumber++;
    }
    
    NSString *totalText;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:kUDDistanceUnits] == MMDistanceUnitsMeters) {
        if (_totalDistance < 1000) {
            totalText = [NSString stringWithFormat:@"%@ %.0lfm", NSLocalizedString(@"word.total", nil), _totalDistance];
        }
        else {
            totalText = [NSString stringWithFormat:@"%@ %.1lfkm", NSLocalizedString(@"word.total", nil), (_totalDistance / 1000)];
        }
    }
    else {
        totalText = [NSString stringWithFormat:@"%@ %.2lfmi", NSLocalizedString(@"word.total", nil), (_totalDistance / 1640)];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _navigationBar.topItem.title = totalText;
    }
    else {
        self.title = totalText;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger number = 0;
    if (_cellTexts.count > 0) {
        // Have two or more pins.
        number = _cellTexts.count;
    }
    else {
        // Display a message.
        number = 1;
    }
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"cell"];
    }
    
    if (_cellTexts.count > 0) {
        // Have two or more pins.
        cell.textLabel.text = [_cellTexts objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:17.0];
    }
    else {
        // Display a message.
        cell.textLabel.font = [UIFont systemFontOfSize:15.0];
        cell.textLabel.text = NSLocalizedString(@"message.nopins", nil);
    }
    
    return cell;
}

#pragma mark - UITableViewDataSource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    }
    else {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
    }
}

#pragma mark - IBAction

- (IBAction)closeDidPush:(UIBarButtonItem *)barButtonItem
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

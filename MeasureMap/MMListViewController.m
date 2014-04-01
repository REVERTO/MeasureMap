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
    self.trackedViewName = NSStringFromClass([self class]);

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateAnnotations:) name:kNOUpdateAnnotations object:nil];
    
    // Change button label.
    _closeButton.title = NSLocalizedString(@"button.close", nil);
    
    [self calcDistance];
}

- (void)updateAnnotations:(NSNotification *)notification
{
    _annotations = [[notification userInfo] valueForKey:@"annotations"];
    [self calcDistance];
    [_tableView reloadData];
}

- (void)calcDistance
{
    _cellTexts = [NSMutableArray array];
    _totalDistance = 0.0;
    _navigationBar.topItem.title = @"";
    
    int cellNumber = _annotations.count - 1;
    if (cellNumber > 0) {
        for (int loopCount = 0; loopCount < cellNumber; loopCount++) {
            NSInteger fromPinNumber = loopCount + 1;
            MKPointAnnotation *fromAnnotation = [_annotations objectAtIndex:loopCount];
            CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:fromAnnotation.coordinate.latitude
                                                                  longitude:fromAnnotation.coordinate.longitude];
            MKPointAnnotation *toAnnotation = [_annotations objectAtIndex:(loopCount + 1)];
            CLLocation *toLocation = [[CLLocation alloc] initWithLatitude:toAnnotation.coordinate.latitude
                                                                longitude:toAnnotation.coordinate.longitude];
            CLLocationDistance distance = [toLocation distanceFromLocation:fromLocation];
            NSMutableString *cellText = [NSMutableString stringWithFormat:@"No.%d %@ No.%d", fromPinNumber, NSLocalizedString(@"word.to", nil), (fromPinNumber + 1)];
            [_cellTexts addObject:cellText];
            
            if (distance < 1000) {
                [cellText appendFormat:@" : %.0lfm", distance];
            }
            else {
                [cellText appendFormat:@" : %.1lfkm", (distance / 1000)];
            }
            _totalDistance += distance;
        }
        if (_totalDistance < 1000) {
            _navigationBar.topItem.title = [NSString stringWithFormat:@"%@ %.0lfm", NSLocalizedString(@"word.total", nil), _totalDistance];
        }
        else {
            _navigationBar.topItem.title = [NSString stringWithFormat:@"%@ %.1lfkm", NSLocalizedString(@"word.total", nil), (_totalDistance / 1000)];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate

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

#pragma mark - IBAction

- (IBAction)closeDidPush:(UIBarButtonItem *)barButtonItem
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

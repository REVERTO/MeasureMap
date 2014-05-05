//
//  MMViewController.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2012/11/01.
//  Copyright (c) 2012年 REVERTO. All rights reserved.
//

#import "MMViewController.h"
#import "MMListViewController.h"
#import "MMLocationInformationViewController.h"
#import "MMAppDelegate.h"
#import "MMCalloutButton.h"
#import <QuartzCore/QuartzCore.h>
#import "MMSettingsViewController.h"

static BOOL _statusbarHidden;

@interface JASidePanelController (Stsbar)

@end

@implementation JASidePanelController (Stsbar)

- (BOOL)prefersStatusBarHidden
{
    return _statusbarHidden;
}

@end

@interface MMViewController ()
{
    NSMutableArray *_annotations;
    BOOL _bannerIsVisible;
    BOOL _isFirst;
    NSArray *_searchPlacemarks;
    BOOL _isSearchLoading;
    BOOL _hasSerachError;
    NSArray *_toolBarItems;
    MKPointAnnotation *_disclosedAnnotation;
    NSMutableArray *_caluculatedRoutes;
    NSArray *_caluculatedDistances;
}

// UI
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *listButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchButton;
@property (weak, nonatomic) IBOutlet ADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *segmentParts;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *settingParts;
@property (weak, nonatomic) IBOutlet UIButton *settingButton;
@property (weak, nonatomic) IBOutlet UILabel *totalDistanceLabel;

// controller
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) UIPopoverController *locationPopover;
@property (strong, nonatomic) MMListViewController *listViewController;

@property UIView *overlay;
@property UIActivityIndicatorView *indicator;

@end

@implementation MMViewController

@synthesize toolBar = _toolBar;

- (void)showLoadingIndicator
{
    self.overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.overlay.backgroundColor = RGBA(0, 0, 0, 0.5);
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.indicator.center = CGPointMake(self.overlay.frame.size.width/2, self.overlay.frame.size.height/2);
    [self.overlay addSubview:self.indicator];
    [self.indicator startAnimating];
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [window addSubview:self.overlay];
}

- (void)hideLoadingIndicator
{
    [self.indicator stopAnimating];
    [self.indicator removeFromSuperview];
    self.indicator = nil;
    [self.overlay removeFromSuperview];
    self.overlay = nil;
}

#pragma mark - UIViewController Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.screenName = NSStringFromClass([self class]);
    _annotations = [NSMutableArray array];
    _isFirst = YES;

    // top parts
    if (!OsVersionLessThan(@"7.0")) {
        _segmentParts.backgroundColor = [UIColor colorWithHex:@"eeeeee" alpha:0.8];
        _segmentParts.layer.borderColor = [UIColor colorWithHex:@"cccccc" alpha:1.0].CGColor;
        _segmentParts.layer.borderWidth = 1.0;
        _segmentParts.layer.cornerRadius = 4.0;
        _settingParts.backgroundColor = [UIColor colorWithHex:@"eeeeee" alpha:0.8];
        _settingParts.layer.borderColor = [UIColor colorWithHex:@"cccccc" alpha:1.0].CGColor;
        _settingParts.layer.borderWidth = 1.0;
        _settingParts.layer.cornerRadius = 4.0;
        _totalDistanceLabel.alpha = 0.0;
        CGRect frame = _segmentParts.frame;
        frame.size.height = 39;
        _segmentParts.frame = frame;
        _segmentedControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kUDSegmentIndex];
    }
    else {
        _segmentParts.hidden = YES;
        _settingParts.hidden = YES;
    }
    
    // tool bar
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.navigationItem.titleView = _toolBar;
        _toolBar.backgroundColor = [UIColor clearColor];
        for (id view in _toolBar.subviews) {
            if (![view isKindOfClass:[UIBarButtonItem class]] && ![view isKindOfClass:[UISearchBar class]] && ![view isKindOfClass:[UISegmentedControl class]]) {
                [(UIView *)view setHidden:YES];
            }
        }
    }
    _clearButton.tintColor = [UIColor lightGrayColor];
    _currentButton.tintColor = [UIColor lightGrayColor];
    _searchBar.placeholder = NSLocalizedString(@"message.search", nil);
    _searchBar.tintColor = [UIColor whiteColor];
    
    if ([self.navigationController.parentViewController isKindOfClass:[UISplitViewController class]]) {
        self.splitViewController = (UISplitViewController *)self.parentViewController.parentViewController;
        self.splitViewController.delegate = self;
        
        _toolBarItems = self.toolBar.items;
        
        NSMutableArray *items = [NSMutableArray array];
        for (id item in _toolBarItems) {
            if (item != _listButton) {
                [items addObject:item];
            }
        }
        [self.toolBar setItems:items animated:NO];
    }

    // notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidRotate:)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deletePinNotified:)
                                                 name:@"deletePin" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAdNotified:)
                                                 name:@"removeAd" object:nil];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUDRemoveAd]) {
        [self removeAdBanner];
    }
    else {
        [self hideAdBannerWithAnimated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    _bannerIsVisible = YES;
    
    if (_isFirst) {
        self.searchDisplayController.active = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGRect rect;
        rect = _searchBar.frame;
        rect.origin.y -= _searchBar.frame.size.height;
        _searchBar.frame = rect;
        _searchBar.hidden = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return  NO;
    }
    else {
        return YES;
    }
}

- (void)viewDidRotate:(id)sender
{
    if (_locationPopover) {
        [_locationPopover dismissPopoverAnimated:NO];
        _locationPopover = nil;
    }
}

#pragma mark - Action

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"MapToList"]) {
        GATrackEvent(@"ButtonTap",@"ListTap",@"AnnotationCount",[NSNumber numberWithInteger:_annotations.count]);
        MMListViewController *listViewController = [segue destinationViewController];
        listViewController.distances = _caluculatedDistances;
    }
}

- (IBAction)returnForSegue:(UIStoryboardSegue *)segue
{
}

- (IBAction)listDidPush:(UIBarButtonItem *)barButtonItem
{
    if (_splitViewController) {
        GATrackEvent(@"ButtonTap",@"ListTap",@"AnnotationCount",[NSNumber numberWithInteger:_annotations.count]);
        [self.popover presentPopoverFromBarButtonItem:barButtonItem
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
    }
}

- (IBAction)currentDidPush:(UIBarButtonItem *)barButtonItem
{
    GATrackEvent(@"ButtonTap",@"CurrentTap",nil,nil);
    if (_mapView.showsUserLocation) {
        _mapView.showsUserLocation = NO;
        _currentButton.tintColor = [UIColor lightGrayColor];
    }
    else {
        [self.locationManager startUpdatingLocation];
    }
}

- (IBAction)searchDidPush:(id)sender
{
    GATrackEvent(@"ButtonTap",@"SearchTap",nil,nil);
    
    if (!OsVersionLessThan(@"7.0")) {
        _statusbarHidden = YES;
        [self setNeedsStatusBarAppearanceUpdate];
        self.segmentParts.hidden = YES;
        self.settingParts.hidden = YES;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect rect;
        rect = _searchBar.frame;
        rect.origin.y = 0;
        _searchBar.frame = rect;
    } completion:^(BOOL finished){
        self.searchDisplayController.active = YES;
    }];
}

- (IBAction)clearDidPush:(UIBarButtonItem *)barButtonItem
{
    GATrackEvent(@"ButtonTap",@"ClearTap",nil,nil);
    
    if (_annotations.count > 0) {
        [_mapView removeAnnotations:_annotations];
        _annotations = [NSMutableArray array];
        _clearButton.tintColor = [UIColor lightGrayColor];

        [self reloadOverlaysWithAnnotations:_annotations];
    }
    else {
        [[iToast makeText:NSLocalizedString(@"message.guidetrash", nil)] show];
    }
}

- (IBAction)didLongPressByRecognaizer:(UILongPressGestureRecognizer *)recognizer
{
    // ロングタップの開始時のみ処理を実施
    if (recognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    // Pinを設置
    CGPoint touchPoint = [recognizer locationInView:_mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = touchMapCoordinate;
    annotation.title = [NSString stringWithFormat:@"No.%lu", (long)(_annotations.count + 1)];
    [_annotations addObject:annotation];
    [_mapView addAnnotation:annotation];

    // PinとPinを線でつなげる
    NSInteger count = _annotations.count;
    if (count == 0) {
        return;
    }
    else if (count < 2) {
        _clearButton.tintColor = [UIColor redColor];
        return;
    }
    else {
        _clearButton.tintColor = [UIColor redColor];
    }
    
    [self reloadOverlaysWithAnnotations:_annotations];
}

- (void)calloutButtonDidTap:(UIButton *)button
{
    GATrackEvent(@"ButtonTap",@"Callout",nil,nil);
    MMCalloutButton *calloutButton = (MMCalloutButton *)button.superview;
    MKPointAnnotation *annotation = calloutButton.annotation;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        MMAppDelegate *appDelegate = (MMAppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.locationInformationVC.coordinate = annotation.coordinate;
        [appDelegate.sidePanelController showRightPanelAnimated:YES];
    }
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        MMLocationInformationViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"MMLocationInformationViewController"];
        viewController.contentSizeForViewInPopover = CGSizeMake(320, 280);
        viewController.coordinate = annotation.coordinate;
        _locationPopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
        [_locationPopover presentPopoverFromRect:button.frame inView:button.superview
                        permittedArrowDirections:(UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight) animated:YES];
    }
    _disclosedAnnotation = annotation;
}

- (void)deletePinNotified:(id)sender
{
    GATrackEvent(@"ButtonTap",@"DeletePin",nil,nil);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        MMAppDelegate *appDelegate = (MMAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.sidePanelController toggleRightPanel:nil];
    }
    else {
        [_locationPopover dismissPopoverAnimated:NO];
        _locationPopover = nil;
    }
    
    [self deletePinAnnotation:_disclosedAnnotation];
}

- (void)removeAdNotified:(id)sender
{
    [self removeAdBanner];
}

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl
{
    [[NSUserDefaults standardUserDefaults] setInteger:segmentedControl.selectedSegmentIndex forKey:kUDSegmentIndex];
    
    [self reloadOverlaysWithAnnotations:_annotations];
}

#pragma mark - Public

- (void)deletePinAnnotation:(MKPointAnnotation *)pinAnnotation
{
    [_mapView removeAnnotation:pinAnnotation];
    [_annotations removeObject:pinAnnotation];
    
    NSInteger count = _annotations.count;
    if (count < 2) {
        _clearButton.tintColor = [UIColor lightGrayColor];
    }
    
    [self reloadOverlaysWithAnnotations:_annotations];
}

#pragma mark Private

- (void)reloadOverlaysWithAnnotations:(NSArray *)annotations
{
    [_mapView removeOverlays:_mapView.overlays];
    
    if (annotations.count < 2) {
        [self hideTotalDistance];
        // 更新通知を送信
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOUpdateAnnotations object:nil userInfo:@{@"distances":@[]}];
        _caluculatedDistances = @[];
        return;
    }
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        NSInteger count = annotations.count;
        CLLocationCoordinate2D coordinates[count];
        for (int loopCount = 0; loopCount < count; loopCount++) {
            MKPointAnnotation *annotation = annotations[loopCount];
            coordinates[loopCount] = CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude);
        }
        MKPolyline *newLine = [MKPolyline polylineWithCoordinates:coordinates count:count];
        [_mapView addOverlay:newLine];
        
        // calc distance
        NSMutableArray *distances = [NSMutableArray array];
        NSInteger cellNumber = _annotations.count - 1;
        for (int loopCount = 0; loopCount < cellNumber; loopCount++) {
            MKPointAnnotation *fromAnnotation = [_annotations objectAtIndex:loopCount];
            CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:fromAnnotation.coordinate.latitude
                                                                  longitude:fromAnnotation.coordinate.longitude];
            MKPointAnnotation *toAnnotation = [_annotations objectAtIndex:(loopCount + 1)];
            CLLocation *toLocation = [[CLLocation alloc] initWithLatitude:toAnnotation.coordinate.latitude
                                                                longitude:toAnnotation.coordinate.longitude];
            CLLocationDistance distance = [toLocation distanceFromLocation:fromLocation];
            [distances addObject:[NSNumber numberWithDouble:distance]];
        }
        
        // 更新通知を送信
        [[NSNotificationCenter defaultCenter] postNotificationName:kNOUpdateAnnotations object:nil userInfo:@{@"distances":distances}];
        _caluculatedDistances = distances;
        [self showTotalDistance];
    }
    else {
        NSMutableArray *mapItems = [NSMutableArray array];
        for (MKPointAnnotation *annotation in annotations) {
            MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:annotation.coordinate addressDictionary:nil]];
            [mapItems addObject:item];
        }
        [self showLoadingIndicator];
        _caluculatedRoutes = [NSMutableArray array];
        [self calculateDirectionsWithMapItems:mapItems rootNo:0 success:^(NSArray *routes) {
            [self hideLoadingIndicator];
            
            NSMutableArray *distances = [NSMutableArray array];
            for (MKRoute *route in routes) {
                [_mapView addOverlay:route.polyline];
                [distances addObject:[NSNumber numberWithDouble:route.distance]];
            }
            
            // 更新通知を送信
            [[NSNotificationCenter defaultCenter] postNotificationName:kNOUpdateAnnotations object:nil userInfo:@{@"distances":distances}];
            _caluculatedDistances = distances;
            [self showTotalDistance];
        } failure:^{
            [self hideLoadingIndicator];
            [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"aleart.failRooting.title", nil)
                                           message:NSLocalizedString(@"aleart.failRooting.message", nil)
                                 cancelButtonTitle:NSLocalizedString(@"button.close", nil)
                                 otherButtonTitles:nil
                                           handler:nil];
        }];
    }
}

- (void)calculateDirectionsWithMapItems:(NSArray *)mapItems rootNo:(NSInteger)rootNo success:(void(^)(NSArray *routes))success failure:(void(^)(void))failure
{
    if (mapItems.count < rootNo + 2) {
        if (failure) failure();
        return;
    };
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = mapItems[rootNo];
    request.destination = mapItems[rootNo + 1];
    request.requestsAlternateRoutes = YES;
    request.transportType = [[NSUserDefaults standardUserDefaults] integerForKey:kUDTransportType];
    [[[MKDirections alloc] initWithRequest:request] calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error) {
            if (failure) failure();
            return;
        };
        if (response.routes.count > 0) {
            [_caluculatedRoutes addObject:response.routes[0]];
        }
        
        if (mapItems.count == rootNo + 2) {
            if (success) success(_caluculatedRoutes);
        }
        else {
            [self calculateDirectionsWithMapItems:mapItems rootNo:(rootNo + 1) success:success failure:failure];
        }
    }];
}

- (void)showTotalDistance
{
    double totalDistance = 0.0;
    for (NSNumber *distance in _caluculatedDistances) {
        totalDistance += distance.doubleValue;
    }

    if ([[NSUserDefaults standardUserDefaults] integerForKey:kUDDistanceUnits] == MMDistanceUnitsMeters) {
        if (totalDistance < 1000) {
            _totalDistanceLabel.text = [NSString stringWithFormat:@"%@ %.0lfm", NSLocalizedString(@"word.total", nil), totalDistance];
        }
        else {
            _totalDistanceLabel.text = [NSString stringWithFormat:@"%@ %.1lfkm", NSLocalizedString(@"word.total", nil), (totalDistance / 1000)];
        }
    }
    else {
        _totalDistanceLabel.text = [NSString stringWithFormat:@"%@ %.2lfmi", NSLocalizedString(@"word.total", nil), (totalDistance / 1640)];
    }

    if (_segmentParts.frame.size.height != 65) {
        _totalDistanceLabel.alpha = 0.0;
        [UIView animateWithDuration:0.4 animations:^{
            CGRect frame = _segmentParts.frame;
            frame.size.height = 65;
            _segmentParts.frame = frame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                _totalDistanceLabel.alpha = 1.0;
            }];
        }];
    }
}

- (void)hideTotalDistance
{
    if (_segmentParts.frame.size.height == 40) return;
    
    [UIView animateWithDuration:0.2 animations:^{
        _totalDistanceLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 animations:^{
            CGRect frame = _segmentParts.frame;
            frame.size.height = 39;
            _segmentParts.frame = frame;
        }];
    }];
}

#pragma mark - MKMapViewDelegate

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    NSLog(@"%s",__FUNCTION__);
    if (_isFirst) {
        _isFirst = NO;
        _mapView.showsUserLocation = NO;
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[MKPointAnnotation class]]) {
        return nil;
    }
    
    static NSString *identifier = @"Pin";
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!view) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        view.animatesDrop = YES;
        view.canShowCallout = YES;
        view.draggable = YES;
    }
    MMCalloutButton *button = [MMCalloutButton instance];
    [button addTarget:self action:@selector(calloutButtonDidTap:) forControlEvents:UIControlEventTouchUpInside];
    button.annotation = annotation;
    view.rightCalloutAccessoryView = button;
    
    return view;
}

- (NSInteger)numberInText:(NSString *)text
{
    NSError *error = nil;
    NSRegularExpression *regexp =
    [NSRegularExpression regularExpressionWithPattern:@"No.(.+)"
                                              options:0
                                                error:&error];
    if (error != nil) {
        return 0;
    }
    else {
        NSTextCheckingResult *match = [regexp firstMatchInString:text
                                                         options:0
                                                           range:NSMakeRange(0, text.length)];
        NSInteger number = 0;
        if (match.numberOfRanges > 1) {
            Log(@"%@", [text substringWithRange:[match rangeAtIndex:0]]);   // マッチした文字列全部
            Log(@"%@", [text substringWithRange:[match rangeAtIndex:1]]);   // 1つ目の文字列
            number = [[text substringWithRange:[match rangeAtIndex:1]] integerValue];
        }
        return number;
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if (![view.annotation isKindOfClass:([MKPointAnnotation class])]) return;
    
    NSInteger number =  [_annotations indexOfObject:view.annotation] + 1;
    [(MKPointAnnotation *)view.annotation setTitle:[NSString stringWithFormat:@"No.%ld", (long)number]];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineView *view = [[MKPolylineView alloc] initWithOverlay:overlay];
    view.strokeColor = [UIColor blueColor];
    view.lineWidth = 5.0;
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    static BOOL _isDragged = NO;
    
    if (_annotations.count < 2) {
        _isDragged = NO;
        return;
    }
    
    switch (newState) {
        case MKAnnotationViewDragStateDragging:
            _isDragged = YES;
            
            break;
            
        case MKAnnotationViewDragStateEnding:
            // 新たにオーバレイを追加
            if (_isDragged) {
                _isDragged = NO;
                
                [self reloadOverlaysWithAnnotations:_annotations];
            }
            break;
            
        default:
            // 何もしない
            break;
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations objectAtIndex:0];
    
    // Display around the present location.
    _mapView.showsUserLocation = YES;
    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
    MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, span);
    [_mapView setRegion:region animated:YES];
    _currentButton.tintColor = [UIColor blueColor];
    
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"message.nolocation", nil)
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"button.close", nil)
                                          otherButtonTitles:nil];
    [alert show];

    [self.locationManager stopUpdatingLocation];
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    Log(@"");
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (!OsVersionLessThan(@"7.0")) {
            _statusbarHidden = NO;
            [self setNeedsStatusBarAppearanceUpdate];
            self.segmentParts.hidden = NO;
            self.settingParts.hidden = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView beginAnimations:@"animateSearchBar" context:NULL];
            
            CGRect rect;
            rect = _searchBar.frame;
            rect.origin.y -= _searchBar.frame.size.height;
            _searchBar.frame = rect;
            
            [UIView commitAnimations];
        });
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    Log(@"");
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:searchString completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            Log(@"%@",error);
            _isSearchLoading = NO;
            _hasSerachError = YES;
        } else {
            _searchPlacemarks = placemarks;
            _isSearchLoading = NO;
            _hasSerachError = NO;
        }
    }];
    _isSearchLoading = YES;
    return YES;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [self.searchDisplayController setActive:YES animated:YES];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    [self.searchDisplayController setActive:NO animated:YES];
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    Log(@"");
    while (_isSearchLoading) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    if (_hasSerachError) {
        return 0;
    }
    else {
        return _searchPlacemarks.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    MKPlacemark *placemark = [_searchPlacemarks objectAtIndex:indexPath.row];
    for (NSString *string in [placemark.addressDictionary valueForKey:@"FormattedAddressLines"]) {
        Log("%@",string);
    }
    cell.textLabel.text = [self adressForPlacemark:placemark];
    
    return cell;
}

- (NSString *)adressForPlacemark:(MKPlacemark *)placemark
{
    NSMutableString *address = [NSMutableString string];
    NSDictionary *dict = placemark.addressDictionary;
    if ([dict valueForKey:@"SubLocality"]) {
        // 地域名あり
        [address appendFormat:@"%@",[dict valueForKey:@"State"]];
        [address appendFormat:@" %@",[dict valueForKey:@"City"]];
        [address appendFormat:@" %@",[dict valueForKey:@"SubLocality"]];
    }
    else if ([dict valueForKey:@"City"]) {
        // 都市名あり
        [address appendFormat:@"%@",[dict valueForKey:@"State"]];
        [address appendFormat:@" %@",[dict valueForKey:@"City"]];
    }
    else {
        // 国名のみ
        [address appendFormat:@"%@",[dict valueForKey:@"Country"]];
    }
    
    return address;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MKPlacemark *placemark = [_searchPlacemarks objectAtIndex:indexPath.row];
    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
    MKCoordinateRegion region = MKCoordinateRegionMake(placemark.location.coordinate, span);
    [_mapView setRegion:region animated:YES];
    
    [self.searchDisplayController setActive:NO animated:YES];
}

#pragma mark - UISplitViewDelegate

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc;
{
    [self.toolBar setItems:_toolBarItems animated:NO];
    
    self.popover = pc;
}

// Master View Controller が表示される直前に呼び出されます。
- (void)splitViewController:(UISplitViewController*)splitController willShowViewController:(UIViewController*)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *items = [NSMutableArray array];
    for (id item in _toolBarItems) {
        if (item != _listButton) {
            [items addObject:item];
        }
    }
    [self.toolBar setItems:items animated:YES];
    
    self.popover = nil;
}

#pragma mark - ADBannerViewDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self showAdBannerWithAnimated:YES];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self hideAdBannerWithAnimated:YES];
}

- (void)showAdBannerWithAnimated:(BOOL)animated
{
    CGFloat duration = animated ? 0.3 : 0.0;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        // iPhoneの場合
        [UIView animateWithDuration:duration animations:^{
            // map view
            CGRect rect;
            rect = _mapView.frame;
            rect.size.height = self.view.frame.size.height - _bannerView.frame.size.height;
            _mapView.frame = rect;
            //tool bar
            rect = _toolBar.frame;
            rect.origin.y = _mapView.frame.size.height - _toolBar.frame.size.height;
            _toolBar.frame = rect;
            //banner view
            rect = _bannerView.frame;
            rect.origin.y = _mapView.frame.size.height;
            _bannerView.frame = rect;
        }];
    }
    else {
        // iPadの場合
        [UIView animateWithDuration:duration animations:^{
            //banner view
            CGRect rect;
            rect = _bannerView.frame;
            rect.origin.y = _mapView.frame.size.height - _bannerView.frame.size.height;
            _bannerView.frame = rect;
        }];
    }
}

- (void)hideAdBannerWithAnimated:(BOOL)animated
{
    CGFloat duration = animated ? 0.3 : 0.0;
    
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            // iPhoneの場合
            [UIView animateWithDuration:duration animations:^{
                // map view
                CGRect rect;
                rect = _mapView.frame;
                rect.size.height = self.view.frame.size.height;
                _mapView.frame = rect;
                //tool bar
                rect = _toolBar.frame;
                rect.origin.y = _mapView.frame.size.height - _toolBar.frame.size.height;
                _toolBar.frame = rect;
                //banner view
                rect = _bannerView.frame;
                rect.origin.y = _mapView.frame.size.height;
                _bannerView.frame = rect;
            }];
        }
        else {
            // iPadの場合
            [UIView animateWithDuration:duration animations:^{
                //banner view
                CGRect rect;
                rect = _bannerView.frame;
                rect.origin.y = _mapView.frame.size.height;
                _bannerView.frame = rect;
            }];
        }
}

- (void)removeAdBanner
{
    [self hideAdBannerWithAnimated:NO];
    _bannerView.delegate = nil;
    [_bannerView removeFromSuperview];
    _bannerView = nil;
}

#pragma mark - Accessor

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = 1.0;
    }
    return _locationManager;
}

@end

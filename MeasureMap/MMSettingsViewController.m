//
//  MMSettingsViewController.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 4/28/14.
//  Copyright (c) 2014 REVERTO. All rights reserved.
//

#import "MMSettingsViewController.h"
#import <StoreKit/StoreKit.h>
#import <MapKit/MapKit.h>
#import "MMAppDelegate.h"

typedef NS_ENUM(NSInteger, MMSettingSection) {
    MMSettingSectionTransportType = 0,
    MMSettingSectionDistanceUnits = 1,
    MMSettingSectionRemoveAd = 2
};

@interface MMSettingsViewController () <SKProductsRequestDelegate,SKPaymentTransactionObserver>

@property (weak, nonatomic) IBOutlet UITableViewCell *walkingCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *automobileCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *metersCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *milesCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *purchaseCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *restoreCell;

@end

@implementation MMSettingsViewController

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
    
    NSInteger index;
    index = [[NSUserDefaults standardUserDefaults] integerForKey:kUDTransportType] == MKDirectionsTransportTypeWalking ? 0 : 1;
    [self checkmarkOnTransportTypeWithIndex:index];
    index = [[NSUserDefaults standardUserDefaults] integerForKey:kUDDistanceUnits] == MMDistanceUnitsMeters ? 0 : 1;
    [self checkmarkOnDistanceUnitsWithIndex:index];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUDRemoveAd]) {
        [self invalidTouchForRemoveAdCells];
    }
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)invalidTouchForRemoveAdCells
{
    self.purchaseCell.textLabel.textColor = [UIColor lightGrayColor];
    self.purchaseCell.userInteractionEnabled = NO;
    self.restoreCell.textLabel.textColor = [UIColor lightGrayColor];
    self.restoreCell.userInteractionEnabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableViewDelegate

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    if (section == 0) {
//        return NSLocalizedString(@"word.locationInformaition", nil);
//    }
//    else {
//        return nil;
//    }
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MMSettingSectionRemoveAd) {
        if (indexPath.row == 0) {
            // purchase
            if (![SKPaymentQueue canMakePayments]) {
                [UIAlertView bk_showAlertViewWithTitle:nil
                                               message:NSLocalizedString(@"aleart.restrictedPurchase.message", nil)
                                     cancelButtonTitle:NSLocalizedString(@"button.close", nil)
                                     otherButtonTitles:nil
                                               handler:nil];
            }
            else {
                NSSet *set = [NSSet setWithObject:@"jp.reverto.MeasureMap.RemoveAds"];
                SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
                productsRequest.delegate = self;
                [productsRequest start];
            }
        }
        else {
            // restore
            [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
            [self showLoadingIndicator];
        }
    }
    else if (indexPath.section == MMSettingSectionTransportType) {
        [self checkmarkOnTransportTypeWithIndex:indexPath.row];
    }
    else if (indexPath.section == MMSettingSectionDistanceUnits) {
        [self checkmarkOnDistanceUnitsWithIndex:indexPath.row];
    }
}

- (void)checkmarkOnTransportTypeWithIndex:(NSInteger)index
{
    if (index == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:MKDirectionsTransportTypeWalking forKey:kUDTransportType];
        _walkingCell.accessoryType = UITableViewCellAccessoryCheckmark;
        _automobileCell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        [[NSUserDefaults standardUserDefaults] setInteger:MKDirectionsTransportTypeAutomobile forKey:kUDTransportType];
        _walkingCell.accessoryType = UITableViewCellAccessoryNone;
        _automobileCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)checkmarkOnDistanceUnitsWithIndex:(NSInteger)index
{
    if (index == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:MMDistanceUnitsMeters forKey:kUDDistanceUnits];
        _metersCell.accessoryType = UITableViewCellAccessoryCheckmark;
        _milesCell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        [[NSUserDefaults standardUserDefaults] setInteger:MMDistanceUnitsMiles forKey:kUDDistanceUnits];
        _metersCell.accessoryType = UITableViewCellAccessoryNone;
        _milesCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (NSString *identifier in response.invalidProductIdentifiers) {
        NSLog(@"%@",identifier);
    }

    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    for (SKProduct *product in response.products) {
        NSLog(@"addPayment");
        [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
        [self showLoadingIndicator];
    }
}

#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                Log(@"SKPaymentTransactionStatePurchasing");
                break;
                
            case SKPaymentTransactionStatePurchased:
                Log(@"SKPaymentTransactionStatePurchased");
                [self hideLoadingIndicator];
                [queue finishTransaction:transaction];
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUDRemoveAd];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"removeAd" object:nil];
                [self invalidTouchForRemoveAdCells];
                [UIAlertView bk_showAlertViewWithTitle:nil
                                               message:NSLocalizedString(@"aleart.completePurchase.message", nil)
                                     cancelButtonTitle:NSLocalizedString(@"button.close", nil)
                                     otherButtonTitles:nil
                                               handler:nil];
                break;
                
            case SKPaymentTransactionStateFailed:
                Log(@"SKPaymentTransactionStateFailed");
                [self hideLoadingIndicator];
                [queue finishTransaction:transaction];
                
                [UIAlertView bk_showAlertViewWithTitle:nil
                                               message:NSLocalizedString(@"aleart.failedPurchase.message", nil)
                                     cancelButtonTitle:NSLocalizedString(@"button.close", nil)
                                     otherButtonTitles:nil
                                               handler:nil];
                break;
                
            case SKPaymentTransactionStateRestored:
                Log(@"SKPaymentTransactionStateRestored");
                [self hideLoadingIndicator];
                [queue finishTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self hideLoadingIndicator];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUDRemoveAd];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeAd" object:nil];
    [self invalidTouchForRemoveAdCells];
    [UIAlertView bk_showAlertViewWithTitle:nil
                                   message:NSLocalizedString(@"aleart.completeRestore.message", nil)
                         cancelButtonTitle:NSLocalizedString(@"button.close", nil)
                         otherButtonTitles:nil
                                   handler:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [self hideLoadingIndicator];

    [UIAlertView bk_showAlertViewWithTitle:nil
                                   message:NSLocalizedString(@"aleart.failedRestore.message", nil)
                         cancelButtonTitle:NSLocalizedString(@"button.close", nil)
                         otherButtonTitles:nil
                                   handler:nil];
}

@end

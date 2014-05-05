//
//  MMAppDelegate.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2012/11/01.
//  Copyright (c) 2012年 REVERTO. All rights reserved.
//

#import "MMAppDelegate.h"
#import "GAI.h"
#import "MMLocationInformationViewController.h"
#import <iToast.h>

@implementation MMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // google analytics tracking.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 10;
#if DEBUG
    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelVerbose];
#endif
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-37381910-1"];
    [[GAI sharedInstance] defaultTracker];
    
    // iToast setting.
    iToastSettings *ts = [iToastSettings getSharedSettings];
    ts.gravity = iToastGravityCenter;
    ts.duration = 2000;

    // initialized check
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kUDInitialized]) {
        [[NSUserDefaults standardUserDefaults] setInteger:MMDistanceUnitsMeters forKey:kUDDistanceUnits];
        [[NSUserDefaults standardUserDefaults] setInteger:MKDirectionsTransportTypeWalking forKey:kUDTransportType];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUDInitialized];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        self.sidePanelController = [[JASidePanelController alloc] init];
        self.sidePanelController.shouldDelegateAutorotateToVisiblePanel = YES;
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        self.mmVC = [storyboard instantiateViewControllerWithIdentifier:@"MMViewController"];
        self.locationInformationVC = [storyboard instantiateViewControllerWithIdentifier:@"MMLocationInformationViewController"];
        
        self.sidePanelController.centerPanel = self.mmVC;
        self.sidePanelController.rightPanel = self.locationInformationVC;
        
        self.splashVC = [MMSplashViewController new];
        self.window.rootViewController = self.splashVC;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView transitionFromView:self.splashVC.view
                                toView:self.sidePanelController.view
                              duration:1.0
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            completion:^(BOOL finished) {
                                self.window.rootViewController = self.sidePanelController;
                            }];
        });
        
        [self.window makeKeyAndVisible];
    }
    else {
        // iPadはStoryBoardから生成
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    self.mmVC.mapView.showsUserLocation = NO;
    self.mmVC.currentButton.tintColor = [UIColor lightGrayColor];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

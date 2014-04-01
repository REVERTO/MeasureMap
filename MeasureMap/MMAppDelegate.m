//
//  MMAppDelegate.m
//  MeasureMap
//
//  Created by Tomoyuki Ito on 2012/11/01.
//  Copyright (c) 2012年 REVERTO. All rights reserved.
//

#import "MMAppDelegate.h"
#import "GAI.h"
#import "MMViewController.h"
#import "MMLocationInformationViewController.h"

@implementation MMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 10;
    [GAI sharedInstance].debug = NO;
    [[GAI sharedInstance].defaultTracker setUseHttps:YES];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-37381910-1"];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        self.sidePanelController = [[JASidePanelController alloc] init];
        self.sidePanelController.shouldDelegateAutorotateToVisiblePanel = YES;
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        MMViewController *mainVC = [storyboard instantiateViewControllerWithIdentifier:@"MMViewController"];
        self.locationInformationVC = [storyboard instantiateViewControllerWithIdentifier:@"MMLocationInformationViewController"];
        
        self.sidePanelController.centerPanel = mainVC;
        self.sidePanelController.rightPanel = self.locationInformationVC;
        
        self.window.rootViewController = self.sidePanelController;
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
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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

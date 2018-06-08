//
//  AppDelegate.m
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#import "AppDelegate.h"
#import "RenderViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  RenderViewController * controller = (RenderViewController *)self.window.rootViewController;
  [controller didEnterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  RenderViewController * controller = (RenderViewController *)self.window.rootViewController;
  [controller willEnterForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

@end

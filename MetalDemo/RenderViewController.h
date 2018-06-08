//
//  RenderViewController.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#if defined(TARGET_IOS)
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import <MetalKit/MetalKit.h>

#if defined(TARGET_IOS)
#define PlatformViewController UIViewController<MTKViewDelegate>
#else
#define PlatformViewController NSViewController<MTKViewDelegate>
#endif

@interface RenderViewController : PlatformViewController

@property(nonatomic, getter=isPaused) BOOL paused;

- (void)didEnterBackground;
- (void)willEnterForeground;

@end

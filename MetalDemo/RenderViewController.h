//
//  RenderViewController.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RenderView.h"

@interface RenderViewController : UIViewController<RenderViewDelegate>

@property (nonatomic, getter=isPaused) BOOL paused;

- (void)didEnterBackground;
- (void)willEnterForeground;

@end


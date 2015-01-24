//
//  RenderView.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 24.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//
//  Based on Apple Metal Samples (https://developer.apple.com/library/ios/samplecode/MetalBasic3D/Introduction/Intro.html)

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>

@protocol RenderViewDelegate;

// view for rendering by means of Metal
@interface RenderView : UIView

@property (nonatomic, weak) id<RenderViewDelegate> delegate;

@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;
@property (nonatomic, readonly) MTLRenderPassDescriptor* renderPassDescriptor;

@property (nonatomic) MTLPixelFormat depthPixelFormat;
@property (nonatomic) MTLPixelFormat stencilPixelFormat;
@property (nonatomic) NSUInteger sampleCount;

- (void)render;
- (void)processBackgroundEntering;

@end

// delegate for render view
@protocol RenderViewDelegate<NSObject>
@required
- (void)resize:(RenderView *)renderView;
- (void)render:(RenderView *)renderView;
@end


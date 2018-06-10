//
//  SkyboxRenderer.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 07.02.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>

#import "../camera/ArcballCamera.h"
#import "../math/Math.h"
#import "../texture/Texture.h"

@interface SkyboxRenderer : NSObject

- (void)setupWithDevice:(id<MTLDevice>)device
                Library:(id<MTLLibrary>)library
           SamplesCount:(NSUInteger)samplesCount
            ColorFormat:(MTLPixelFormat)colorFormat
            DepthFormat:(MTLPixelFormat)depthFormat
   InflightBuffersCount:(NSUInteger)buffersCount;

- (void)updateWithCamera:(ArcballCamera &)camera
              Projection:(const matrix_float4x4 &)projection
           IndexOfBuffer:(NSUInteger)bufferIndex;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder
                  Texture:(Texture *)skyboxTexture
            IndexOfBuffer:(NSUInteger)bufferIndex;

@end

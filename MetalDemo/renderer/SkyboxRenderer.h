//
//  SkyboxRenderer.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 07.02.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#import <Metal/Metal.h>
#import "../RenderView.h"
#import "../texture/Texture.h"
#import "../math/Math.h"
#import "../camera/ArcballCamera.h"

@interface SkyboxRenderer : NSObject

- (void)setupWithView:(RenderView*)renderView
              Library:(id<MTLLibrary>)library InflightBuffersCount:(NSUInteger)buffersCount;

- (void)updateWithCamera:(ArcballCamera&)camera
            Projection:(const matrix_float4x4&)projection
         IndexOfBuffer:(NSUInteger)bufferIndex;

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder
                  Texture:(Texture*)skyboxTexture
            IndexOfBuffer:(NSUInteger)bufferIndex;

@end


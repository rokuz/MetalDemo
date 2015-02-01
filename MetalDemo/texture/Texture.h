//
//  Texture.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 31.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//
//  Based on https://developer.apple.com/library/ios/samplecode/MetalTexturedQuad/Introduction/Intro.html

#import <Metal/Metal.h>

@interface Texture : NSObject

@property (nonatomic, readonly) id <MTLTexture> texture;
@property (nonatomic, readonly) MTLTextureType target;
@property (nonatomic, readonly) uint32_t width;
@property (nonatomic, readonly) uint32_t height;
@property (nonatomic, readonly) uint32_t depth;
@property (nonatomic, readonly) BOOL mipMapsGenerated;

@property (atomic, readonly) BOOL isReady;

- (id) initWithResourceName:(NSString *)name
                  Extension:(NSString *)ext;

- (BOOL) loadWithDevice:(id<MTLDevice>)device Asynchronously:(BOOL)async;

- (void) generateMipMaps:(id<MTLBlitCommandEncoder>)commandEncoder;

@end

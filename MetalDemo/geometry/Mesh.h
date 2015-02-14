//
//  Mesh.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 31.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#import <Metal/Metal.h>
#import <simd/simd.h>

@interface Mesh : NSObject

@property (nonatomic, readonly) id <MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id <MTLBuffer> indexBuffer;
@property (nonatomic, readonly) uint32_t groupsCount;
@property (atomic, readonly) BOOL isReady;

@property (nonatomic, readonly) uint32_t vertexSize;
@property (nonatomic, readonly) uint32_t verticesCount;
@property (nonatomic, readonly) uint32_t indicesCount;

@property (nonatomic, readonly) simd::float3 boundingBoxMin;
@property (nonatomic, readonly) simd::float3 boundingBoxMax;

- (id) initWithResourceName:(NSString *)name;
- (BOOL) loadWithDevice:(id<MTLDevice>)device Asynchronously:(BOOL)async;
- (uint32_t) indexBufferOffsetForGroup:(uint32_t)groupIndex;
- (uint32_t) indicesCountForGroup:(uint32_t)groupIndex;
- (void) drawGroup:(uint32_t)groupIndex WithEncoder:(id <MTLRenderCommandEncoder>)renderEncoder;
- (void) drawAllWithEncoder:(id <MTLRenderCommandEncoder>)renderEncoder;
- (void) drawGroup:(uint32_t)groupIndex
         Instances:(uint32_t)instances WithEncoder:(id <MTLRenderCommandEncoder>)renderEncoder;
- (void) drawAllInstanced:(uint32_t)instances WithEncoder:(id <MTLRenderCommandEncoder>)renderEncoder;

@end
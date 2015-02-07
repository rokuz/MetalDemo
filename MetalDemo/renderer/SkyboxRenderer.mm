//
//  SkyboxRenderer.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 07.02.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#import "SkyboxRenderer.h"
#import "../math/Math.h"
#import "../geometry/Primitives.h"

typedef struct
{
    matrix_float4x4 viewProjection;
} uniforms_t;


@implementation SkyboxRenderer
{
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    id <MTLBuffer> _vertexBuffer;
    id <MTLBuffer> _dynamicUniformBuffer;
    uniforms_t _uniformBuffer;
}

- (void)dealloc
{
    _pipelineState = nil;
    _depthState = nil;
    _vertexBuffer = nil;
    _dynamicUniformBuffer = nil;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _pipelineState = nil;
        _depthState = nil;
        _vertexBuffer = nil;
        _dynamicUniformBuffer = nil;
    }
    return self;
}

- (void)setupWithView:(RenderView*)renderView
              Library:(id<MTLLibrary>)library InflightBuffersCount:(NSUInteger)buffersCount
{
    NSUInteger sz = sizeof(_uniformBuffer) * buffersCount;
    _dynamicUniformBuffer = [renderView.device newBufferWithLength:sz options:0];
    _dynamicUniformBuffer.label = @"Skybox uniform buffer";
    
    id <MTLFunction> fragmentProgram = [library newFunctionWithName:@"psSkybox"];
    id <MTLFunction> vertexProgram = [library newFunctionWithName:@"vsSkybox"];
    
    _vertexBuffer = [renderView.device newBufferWithBytes:(Primitives::cube())
                                                   length:(Primitives::cubeSizeInBytes())
                                                  options:MTLResourceOptionCPUCacheModeDefault];
    _vertexBuffer.label = @"Skybox vertex buffer";
    
    // pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Skybox pipeline";
    [pipelineStateDescriptor setSampleCount: renderView.sampleCount];
    [pipelineStateDescriptor setVertexFunction:vertexProgram];
    [pipelineStateDescriptor setFragmentFunction:fragmentProgram];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError* error = NULL;
    _pipelineState = [renderView.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState)
    {
        NSLog(@"Failed to created skybox pipeline state, error %@", error);
    }
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    depthStateDesc.depthWriteEnabled = NO;
    _depthState = [renderView.device newDepthStencilStateWithDescriptor:depthStateDesc];
}

- (void)updateWithCamera:(ArcballCamera&)camera
              Projection:(const matrix_float4x4&)projection
           IndexOfBuffer:(NSUInteger)bufferIndex
{
    matrix_float4x4 model = Math::translate(camera.getCurrentViewPosition());
    matrix_float4x4 modelViewMatrix = matrix_multiply(camera.getView(), model);
    _uniformBuffer.viewProjection = matrix_multiply(projection, modelViewMatrix);
    
    uint8_t* bufferPointer = (uint8_t*)[_dynamicUniformBuffer contents] + (sizeof(_uniformBuffer) * bufferIndex);
    memcpy(bufferPointer, &_uniformBuffer, sizeof(_uniformBuffer));
}

- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder
                  Texture:(Texture*)skyboxTexture
            IndexOfBuffer:(NSUInteger)bufferIndex
{
    [encoder pushDebugGroup:@"Draw skybox"];
    [encoder setDepthStencilState:_depthState];
    [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:_dynamicUniformBuffer offset:(sizeof(_uniformBuffer) * bufferIndex) atIndex:1];
    [encoder setFragmentTexture:skyboxTexture.texture atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36 instanceCount:1];
    [encoder popDebugGroup];
}

@end

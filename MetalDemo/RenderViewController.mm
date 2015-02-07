//
//  RenderViewController.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#import "RenderViewController.h"
#import "math/Math.h"
#import "camera/ArcballCamera.h"
#import "geometry/Primitives.h"
#import "geometry/Mesh.h"
#import "texture/Texture.h"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

static const NSUInteger MAX_INFLIGHT_BUFFERS = 3;

typedef struct
{
    matrix_float4x4 modelViewProjection;
    matrix_float4x4 model;
    simd::float3 viewPosition;
} uniforms_t;

@implementation RenderViewController
{
    // infrastructure
    CADisplayLink* _timer;
    BOOL _renderLoopPaused;
    dispatch_semaphore_t _inflightSemaphore;
    BOOL _firstFrameRendered;
    CFTimeInterval _lastTime;
    CFTimeInterval _frameTime;
    ArcballCamera camera;
    
    // renderer
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    
    Texture *_defDiffuseTexture;
    Texture *_defNormalTexture;
    
    Mesh *_mesh;
    Texture *_diffuseTexture;
    Texture *_normalTexture;
    id <MTLBuffer> _dynamicUniformBuffer;
    uint8_t _currentUniformBufferIndex;
    
    // uniforms
    matrix_float4x4 _projectionMatrix;
    matrix_float4x4 _viewMatrix;
    uniforms_t _uniformBuffer;
}

#pragma mark - Infrastructure

- (void)dealloc
{
    [self cleanup];
    [self stopTimer];
    _timer = 0;
}

- (void)initCommon
{
    _firstFrameRendered = NO;
    _lastTime = 0;
    _frameTime = 0;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [self initCommon];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if(self)
    {
        [self initCommon];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if(self)
    {
        [self initCommon];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    ((RenderView*)self.view).delegate = self;
    [self configure: (RenderView*)self.view];
    
    _currentUniformBufferIndex = 0;
    _inflightSemaphore = dispatch_semaphore_create(MAX_INFLIGHT_BUFFERS);
    
    [self setupMetal: ((RenderView*)self.view).device];
    [self startTimer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didEnterBackground
{
    NSLog(@"Rendering stopped");
    _renderLoopPaused = YES;
    _timer.paused = YES;
    [(RenderView*)self.view processBackgroundEntering];
}

- (void)willEnterForeground
{
     NSLog(@"Rendering started");
    _renderLoopPaused = NO;
    _timer.paused = NO;
    
    _firstFrameRendered = NO;
    _lastTime = 0;
    _frameTime = 0;
}

- (BOOL)isPaused
{
    return _renderLoopPaused;
}

- (void)startTimer
{
    _timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(_renderloop)];
    [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopTimer
{
    [_timer invalidate];
}

- (void)_renderloop
{
    if(!_firstFrameRendered)
    {
        _frameTime = 0;
        _lastTime = CACurrentMediaTime();
        _firstFrameRendered = YES;
    }
    else
    {
        CFTimeInterval currentTime = CACurrentMediaTime();
        _frameTime = currentTime - _lastTime;
        _lastTime = currentTime;
    }
    
    [(RenderView*)self.view render];
}

#pragma mark - Renderer

- (void)configure:(RenderView*)renderView
{
    renderView.sampleCount = 1;
    camera.init(-50.0f, -20.0f, 35.0f);
}

- (void)setupMetal:(id<MTLDevice>)device
{
    _commandQueue = [device newCommandQueue];
    _defaultLibrary = [device newDefaultLibrary];
    
    [self loadAssets: device];
}

- (void)cleanup
{
    _mesh = nil;
    _commandQueue = nil;
    _defaultLibrary = nil;
    _pipelineState = nil;
    _depthState = nil;
    _dynamicUniformBuffer = nil;
    _diffuseTexture = nil;
    _normalTexture = nil;
    _defDiffuseTexture = nil;
    _defNormalTexture = nil;
}

- (void)loadAssets:(id<MTLDevice>)device
{
    NSUInteger sz = sizeof(_uniformBuffer) * MAX_INFLIGHT_BUFFERS;
    _dynamicUniformBuffer = [device newBufferWithLength:sz options:0];
    _dynamicUniformBuffer.label = @"Uniform buffer";

    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"psLighting"];
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"vsLighting"];
    
    // default textures
    _defDiffuseTexture = [[Texture alloc] initWithResourceName:@"default_diff" Extension:@"png"];
    [_defDiffuseTexture loadWithDevice:device Asynchronously:NO];
    _defNormalTexture = [[Texture alloc] initWithResourceName:@"default_normal" Extension:@"png"];
    [_defNormalTexture loadWithDevice:device Asynchronously:NO];
    
    // mesh
    _mesh = [[Mesh alloc] initWithResourceName:@"spaceship"];
    [_mesh loadWithDevice:device Asynchronously:YES];
    
    // textures
    _diffuseTexture = [[Texture alloc] initWithResourceName:@"spaceship_diff" Extension:@"png"];
    [_diffuseTexture loadWithDevice:device Asynchronously:YES];
    _normalTexture = [[Texture alloc] initWithResourceName:@"spaceship_normal" Extension:@"png"];
    [_normalTexture loadWithDevice:device Asynchronously:YES];
    
    // pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Simple pipeline";
    [pipelineStateDescriptor setSampleCount: ((RenderView*)self.view).sampleCount];
    [pipelineStateDescriptor setVertexFunction:vertexProgram];
    [pipelineStateDescriptor setFragmentFunction:fragmentProgram];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError* error = NULL;
    _pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [device newDepthStencilStateWithDescriptor:depthStateDesc];
}

- (void)render:(RenderView*)renderView
{
    dispatch_semaphore_wait(_inflightSemaphore, DISPATCH_TIME_FOREVER);
    
    [self update];
    
    MTLRenderPassDescriptor* renderPassDescriptor = renderView.renderPassDescriptor;
    id <CAMetalDrawable> drawable = renderView.currentDrawable;
    
    // new command buffer
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Simple command buffer";
    
    // generate mipmaps
    [_diffuseTexture generateMipMapsIfNecessary:commandBuffer];
    [_normalTexture generateMipMapsIfNecessary:commandBuffer];
    
    // render encoder
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    if (_mesh.isReady)
    {
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder pushDebugGroup:@"Draw mesh"];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setVertexBuffer:_mesh.vertexBuffer offset:0 atIndex:0 ];
        [renderEncoder setVertexBuffer:_dynamicUniformBuffer
                                offset:(sizeof(_uniformBuffer) * _currentUniformBufferIndex)
                               atIndex:1 ];
        [renderEncoder setFragmentTexture:(_diffuseTexture.isReady ? _diffuseTexture.texture : _defDiffuseTexture.texture)
                                  atIndex:0];
        [renderEncoder setFragmentTexture:(_normalTexture.isReady ? _normalTexture.texture : _defNormalTexture.texture)
                                  atIndex:1];
        [_mesh drawAllWithEncoder:renderEncoder];
        [renderEncoder popDebugGroup];
    }
    [renderEncoder endEncoding];

    dispatch_semaphore_t block_sema = _inflightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];
    
    _currentUniformBufferIndex = (_currentUniformBufferIndex + 1) % MAX_INFLIGHT_BUFFERS;
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)resize:(RenderView*)renderView
{
    float aspect = fabsf(renderView.bounds.size.width / renderView.bounds.size.height);
    _projectionMatrix = Math::perspectiveFov(65.0f, aspect, 0.1f, 100.0f);
    _viewMatrix = camera.getView();
}

- (void)update
{
    _viewMatrix = camera.getView();
    matrix_float4x4 model = Math::rotate(-90, 1, 0, 0);
    matrix_float4x4 modelViewMatrix = matrix_multiply(_viewMatrix, model);
    _uniformBuffer.model = model;
    _uniformBuffer.modelViewProjection = matrix_multiply(_projectionMatrix, modelViewMatrix);
    _uniformBuffer.viewPosition = camera.getCurrentViewPosition();
    
    uint8_t* bufferPointer = (uint8_t*)[_dynamicUniformBuffer contents] + (sizeof(_uniformBuffer) * _currentUniformBufferIndex);
    memcpy(bufferPointer, &_uniformBuffer, sizeof(_uniformBuffer));
}

#pragma mark - Input handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray* touchesArray = [touches allObjects];
    if (touches.count == 1)
    {
        if (!camera.isRotatingNow())
        {
            CGPoint pos = [touchesArray[0] locationInView: self.view];
            camera.startRotation(pos.x, pos.y);
        }
        else
        {
            // here we put second finger
            simd::float2 lastPos = camera.getLastFingerPosition();
            camera.stopRotation();
            CGPoint pos = [touchesArray[0] locationInView: self.view];
            float d = vector_distance(simd::float2 { (float)pos.x, (float)pos.y }, lastPos);
            camera.startZooming(d);
        }
    }
    else if (touches.count == 2)
    {
        CGPoint pos1 = [touchesArray[0] locationInView: self.view];
        CGPoint pos2 = [touchesArray[1] locationInView: self.view];
        float d = vector_distance(simd::float2 { (float)pos1.x, (float)pos1.y },
                                  simd::float2 { (float)pos2.x, (float)pos2.y });
        camera.startZooming(d);
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray* touchesArray = [touches allObjects];
    if (touches.count != 0 && camera.isRotatingNow())
    {
        CGPoint pos = [touchesArray[0] locationInView: self.view];
        camera.updateRotation(pos.x, pos.y);
    }
    else if (touches.count == 2 && camera.isZoomingNow())
    {
        CGPoint pos1 = [touchesArray[0] locationInView: self.view];
        CGPoint pos2 = [touchesArray[1] locationInView: self.view];
        float d = vector_distance(simd::float2 { (float)pos1.x, (float)pos1.y },
                                  simd::float2 { (float)pos2.x, (float)pos2.y });
        camera.updateZooming(d);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    camera.stopRotation();
    camera.stopZooming();
}

@end

//
//  RenderView.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 24.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//
//  Based on Apple Metal Samples (https://developer.apple.com/library/ios/samplecode/MetalBasic3D/Introduction/Intro.html)

#import "RenderView.h"

@implementation RenderView
{
@private
    __weak CAMetalLayer * _metalLayer;
    BOOL _layerSizeDidUpdate;
    id<MTLTexture> _depthTexture;
    id<MTLTexture> _stencilTexture;
    id<MTLTexture> _msaaTexture;
}
@synthesize currentDrawable = _currentDrawable;
@synthesize renderPassDescriptor = _renderPassDescriptor;

+ (Class)layerClass
{
    return [CAMetalLayer class];
}

- (void)initCommon
{
    self.opaque = YES;
    self.backgroundColor = nil;
    
    _metalLayer = (CAMetalLayer *)self.layer;
    _device = MTLCreateSystemDefaultDevice();
    _metalLayer.device = _device;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _metalLayer.framebufferOnly = YES;
    
    _sampleCount = 1;
    _depthPixelFormat = MTLPixelFormatDepth32Float;
    _stencilPixelFormat = MTLPixelFormatInvalid;
}

- (void)didMoveToWindow
{
    self.contentScaleFactor = self.window.screen.nativeScale;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if(self)
    {
        [self initCommon];
    }
    return self;
}

- (void)processBackgroundEntering
{
    _depthTexture = nil;
    _stencilTexture = nil;
    _msaaTexture = nil;
}

- (void)setupRenderPassDescriptorForTexture:(id <MTLTexture>)texture
{
    if (_renderPassDescriptor == nil)
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    // init/update default render target
    MTLRenderPassColorAttachmentDescriptor* colorAttachment = _renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture = texture;
    colorAttachment.loadAction = MTLLoadActionClear;
    colorAttachment.clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);
    if(_sampleCount > 1)
    {
        BOOL doUpdate = (_msaaTexture.width != texture.width) || ( _msaaTexture.height != texture.height) || ( _msaaTexture.sampleCount != _sampleCount);
        if(!_msaaTexture || (_msaaTexture && doUpdate))
        {
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatBGRA8Unorm
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            desc.textureType = MTLTextureType2DMultisample;
            desc.sampleCount = _sampleCount;
            desc.usage = MTLTextureUsageRenderTarget;
            _msaaTexture = [_device newTextureWithDescriptor: desc];
            _msaaTexture.label = @"Default MSAA render target";
        }
        
        colorAttachment.texture = _msaaTexture;
        colorAttachment.resolveTexture = texture;
        colorAttachment.storeAction = MTLStoreActionMultisampleResolve;
    }
    else
    {
        colorAttachment.storeAction = MTLStoreActionStore;
    }
    
    // init/update default depth buffer
    if(_depthPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate = (_depthTexture.width != texture.width) || (_depthTexture.height != texture.height) || (_depthTexture.sampleCount != _sampleCount);
        if(!_depthTexture || doUpdate)
        {
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _depthPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            desc.usage = MTLTextureUsageRenderTarget;
            
            _depthTexture = [_device newTextureWithDescriptor: desc];
            _depthTexture.label = @"Default depth buffer";
            
            MTLRenderPassDepthAttachmentDescriptor* depthAttachment = _renderPassDescriptor.depthAttachment;
            depthAttachment.texture = _depthTexture;
            depthAttachment.loadAction = MTLLoadActionClear;
            depthAttachment.storeAction = MTLStoreActionDontCare;
            depthAttachment.clearDepth = 1.0;
        }
    }
    
    // init/update default stencil buffer
    if(_stencilPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate = (_stencilTexture.width != texture.width) || (_stencilTexture.height != texture.height) || (_stencilTexture.sampleCount != _sampleCount);
        if (!_stencilTexture || doUpdate)
        {
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _stencilPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _stencilTexture = [_device newTextureWithDescriptor: desc];
            _stencilTexture.label = @"Default stencil buffer";
            
            MTLRenderPassStencilAttachmentDescriptor* stencilAttachment = _renderPassDescriptor.stencilAttachment;
            stencilAttachment.texture = _stencilTexture;
            stencilAttachment.loadAction = MTLLoadActionClear;
            stencilAttachment.storeAction = MTLStoreActionDontCare;
            stencilAttachment.clearStencil = 0;
        }
    }
}

- (MTLRenderPassDescriptor*)renderPassDescriptor
{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    [self setupRenderPassDescriptorForTexture: drawable.texture];

    return _renderPassDescriptor;
}

- (id <CAMetalDrawable>)currentDrawable
{
    // if we are here, some code demands to render a frame. So we have to wait
    // a valid drawable object
    while(_currentDrawable == nil)
        _currentDrawable = [_metalLayer nextDrawable];
    
    return _currentDrawable;
}

- (void)render
{
    @autoreleasepool
    {
        // handle resizing
        if(_layerSizeDidUpdate)
        {
            CGSize drawableSize = self.bounds.size;
            drawableSize.width  *= self.contentScaleFactor;
            drawableSize.height *= self.contentScaleFactor;
            _metalLayer.drawableSize = drawableSize;
            [_delegate resize:self];
            _layerSizeDidUpdate = NO;
        }
        
        // call render in delegate
        [self.delegate render:self];
        
        // kill current drawable
        _currentDrawable = nil;
    }
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:contentScaleFactor];
    _layerSizeDidUpdate = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _layerSizeDidUpdate = YES;
}

@end

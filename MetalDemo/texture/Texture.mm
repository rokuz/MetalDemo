//
//  Texture.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 31.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//
//  Based on https://developer.apple.com/library/ios/samplecode/MetalTexturedQuad/Introduction/Intro.html

#import <UIKit/UIKit.h>
#import "Texture.h"

@implementation Texture
{
@private
    id <MTLTexture> _texture;
    MTLTextureType _target;
    uint32_t _width;
    uint32_t _height;
    uint32_t _depth;
    MTLPixelFormat _format;
    NSString *_path;
    BOOL _isReady;
    BOOL _mipMapsGenerated;
}

- (instancetype) initWithResourceName:(NSString *)name
                            Extension:(NSString *)ext
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    if(!path)
    {
        return nil;
    }
    
    self = [super init];
    if(self)
    {
        _path = path;
        _width = 0;
        _height = 0;
        _depth = 1;
        _format = MTLPixelFormatRGBA8Unorm;
        _target = MTLTextureType2D;
        _texture = nil;
        _isReady = false;
        _mipMapsGenerated = false;
    }
    return self;
}

- (void) dealloc
{
    _path = nil;
    _texture = nil;
    _isReady = false;
}

- (BOOL) loadWithDevice:(id<MTLDevice>)device Asynchronously:(BOOL)async
{
    if (async)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^
        {
            @autoreleasepool
            {
                [self loadFromFileWithDevice:device];
            }
        });
        return YES;
    }
    return [self loadFromFileWithDevice:device];
}

- (BOOL) loadFromFileWithDevice:(id <MTLDevice>)device
{
    UIImage *image = [UIImage imageWithContentsOfFile:_path];
    if(!image) return NO;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if(!colorSpace) return NO;
    
    _width  = uint32_t(CGImageGetWidth(image.CGImage));
    _height = uint32_t(CGImageGetHeight(image.CGImage));
    uint32_t rowBytes = _width * 4;
    
    CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, rowBytes, colorSpace,
                                                 CGBitmapInfo(kCGImageAlphaPremultipliedLast));
    
    CGColorSpaceRelease(colorSpace);
    if(!context) return NO;
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, _width, _height);
    CGContextClearRect(context, bounds);
    CGContextDrawImage(context, bounds, image.CGImage);
    
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_format
                                                                                       width:_width
                                                                                      height:_height
                                                                                   mipmapped:YES];
    if(!texDesc)
    {
        CGContextRelease(context);
        return NO;
    }

    _target = texDesc.textureType;
    _texture = [device newTextureWithDescriptor:texDesc];
    if(!_texture)
    {
        CGContextRelease(context);
        return NO;
    }
    
    const void *pixels = CGBitmapContextGetData(context);
    if(pixels != NULL)
    {
        MTLRegion region = MTLRegionMake2D(0, 0, _width, _height);
        [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:pixels
                    bytesPerRow:rowBytes];
    }
    
    CGContextRelease(context);
    
    _isReady = YES;
    return YES;
}

- (void) generateMipMapsIfNecessary:(id<MTLCommandBuffer>)commandBuffer
{
    if (_mipMapsGenerated || !_isReady) return;
    
    id <MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    [blitEncoder generateMipmapsForTexture:_texture];
    [blitEncoder endEncoding];

    _mipMapsGenerated = YES;
}

@end

//
//  Texture.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 31.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//
//  Based on
//  https://developer.apple.com/library/ios/samplecode/MetalTexturedQuad/Introduction/Intro.html

#if defined(TARGET_IOS)
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "Texture.h"

@implementation Texture
{
@private
  id<MTLTexture> _texture;
  MTLTextureType _target;
  uint32_t _width;
  uint32_t _height;
  uint32_t _depth;
  MTLPixelFormat _format;
  NSArray * _paths;
  BOOL _isReady;
  BOOL _mipMapsGenerated;
}

struct ImageData
{
  unsigned int width;
  unsigned int height;
  const void * pixels;
  CGContextRef context;
  ImageData() : width(0), height(0), pixels(0), context(0) {}
};

- (instancetype)initWithResourceName:(NSString *)name Extension:(NSString *)ext
{
  NSString * path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
  if (!path)
  {
    return nil;
  }

  self = [super init];
  if (self)
  {
    _paths = [NSArray arrayWithObject:path];
    _width = 0;
    _height = 0;
    _depth = 1;
    _format = MTLPixelFormatRGBA8Unorm;
    _target = MTLTextureType2D;
    _texture = nil;
    _isReady = NO;
    _mipMapsGenerated = NO;
  }
  return self;
}

- (instancetype)initCubeWithResourceNames:(NSArray *)names Extension:(NSString *)ext
{
  if (names.count != 6)
    return nil;

  NSMutableArray * paths = [NSMutableArray arrayWithCapacity:names.count];
  for (int i = 0; i < names.count; i++)
  {
    NSString * path = [[NSBundle mainBundle] pathForResource:names[i] ofType:ext];
    if (!path)
      return nil;
    [paths addObject:path];
  }

  self = [super init];
  if (self)
  {
    _paths = paths;
    _width = 0;
    _height = 0;
    _depth = 1;
    _format = MTLPixelFormatRGBA8Unorm;
    _target = MTLTextureTypeCube;
    _texture = nil;
    _isReady = NO;
    _mipMapsGenerated = NO;
  }
  return self;
}

- (void)dealloc
{
  _paths = nil;
  _texture = nil;
  _isReady = false;
}

- (BOOL)loadWithDevice:(id<MTLDevice>)device Asynchronously:(BOOL)async
{
  if (async)
  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      @autoreleasepool
      {
        [self loadFromFileWithDevice:device];
      }
    });
    return YES;
  }
  return [self loadFromFileWithDevice:device];
}

+ (ImageData)loadImageData:(NSString *)path
{
  ImageData result;

#if defined(TARGET_IOS)
  UIImage * image = [UIImage imageWithContentsOfFile:path];
#else
  NSImage * image = [[NSImage alloc] initWithContentsOfFile:path];
#endif
  if (!image)
    return ImageData();

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  if (!colorSpace)
    return ImageData();

#if defined(TARGET_IOS)
  result.width = uint32_t(CGImageGetWidth(image.CGImage));
  result.height = uint32_t(CGImageGetHeight(image.CGImage));
#else
  NSImageRep * rep = [[image representations] objectAtIndex:0];
  result.width = uint32_t(rep.pixelsWide);
  result.height = uint32_t(rep.pixelsHigh);
#endif
  uint32_t rowBytes = result.width * 4;

  CGContextRef context =
      CGBitmapContextCreate(0, result.width, result.height, 8, rowBytes, colorSpace,
                            CGBitmapInfo(kCGImageAlphaPremultipliedLast));

  CGColorSpaceRelease(colorSpace);
  if (!context)
    return ImageData();

  CGRect bounds = CGRectMake(0.0f, 0.0f, result.width, result.height);
  CGContextClearRect(context, bounds);
#if defined(TARGET_IOS)
  CGContextDrawImage(context, bounds, image.CGImage);
#else
  NSRect imageRect = NSMakeRect(0, 0, result.width, result.height);
  CGImageRef cgImage = [image CGImageForProposedRect:&imageRect context:nil hints:nil];
  CGContextDrawImage(context, bounds, cgImage);
#endif

  result.pixels = CGBitmapContextGetData(context);
  if (result.pixels == 0)
  {
    CGContextRelease(context);
    return ImageData();
  }

  result.context = context;
  return result;
}

+ (void)releaseImageData:(ImageData &)imageData
{
  if (imageData.context != 0)
  {
    CGContextRelease(imageData.context);
    imageData.context = 0;
  }
  imageData.pixels = 0;
}

- (BOOL)loadFromFileWithDevice:(id<MTLDevice>)device
{
  if (_target == MTLTextureType2D)
  {
    [self load2DFromFileWithDevice:device];
  }
  else if (_target == MTLTextureTypeCube)
  {
    [self loadCubeFromFileWithDevice:device];
  }
  return NO;
}

- (BOOL)load2DFromFileWithDevice:(id<MTLDevice>)device
{
  ImageData imageData = [Texture loadImageData:_paths[0]];
  if (imageData.pixels == 0)
    return NO;

  _width = imageData.width;
  _height = imageData.height;
  MTLTextureDescriptor * texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_format
                                                                                      width:_width
                                                                                     height:_height
                                                                                  mipmapped:YES];
  if (!texDesc)
  {
    [Texture releaseImageData:imageData];
    return NO;
  }

  _target = texDesc.textureType;
  _texture = [device newTextureWithDescriptor:texDesc];
  if (!_texture)
  {
    [Texture releaseImageData:imageData];
    return NO;
  }

  uint32_t rowBytes = _width * 4;
  MTLRegion region = MTLRegionMake2D(0, 0, _width, _height);
  [_texture replaceRegion:region mipmapLevel:0 withBytes:imageData.pixels bytesPerRow:rowBytes];

  [Texture releaseImageData:imageData];
  _isReady = YES;

  return YES;
}

- (BOOL)loadCubeFromFileWithDevice:(id<MTLDevice>)device
{
  ImageData imageData = [Texture loadImageData:_paths[0]];
  if (imageData.pixels == 0)
    return NO;
  if (imageData.width != imageData.height)
    return NO;
  _width = _height = _depth = imageData.width;

  MTLTextureDescriptor * texDesc =
      [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:_format size:_width mipmapped:YES];
  if (!texDesc)
  {
    [Texture releaseImageData:imageData];
    return NO;
  }

  _target = texDesc.textureType;
  _texture = [device newTextureWithDescriptor:texDesc];
  if (!_texture)
  {
    [Texture releaseImageData:imageData];
    return NO;
  }

  uint32_t rowBytes = _width * 4;
  uint32_t imageBytes = _width * _width * 4;
  MTLRegion region = MTLRegionMake2D(0, 0, _width, _width);
  for (int i = 0; i < 6; i++)
  {
    if (i > 0)
    {
      imageData = [Texture loadImageData:_paths[i]];
      if (imageData.pixels == 0 || imageData.width != imageData.height)
      {
        [Texture releaseImageData:imageData];
        _texture = nil;
        return NO;
      }
    }

    [_texture replaceRegion:region
                mipmapLevel:0
                      slice:i
                  withBytes:imageData.pixels
                bytesPerRow:rowBytes
              bytesPerImage:imageBytes];

    [Texture releaseImageData:imageData];
  }

  _isReady = YES;

  return YES;
}

- (void)generateMipMapsIfNecessary:(id<MTLCommandBuffer>)commandBuffer
{
  if (_mipMapsGenerated || !_isReady)
    return;

  id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
  [blitEncoder generateMipmapsForTexture:_texture];
  [blitEncoder endEncoding];

  _mipMapsGenerated = YES;
}

@end

//
//  Mesh.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 31.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

// Geom format description:
//
// 4 bytes		- magic number
// 3 x 4 bytes	- bounding box min (x, y, z)
// 3 x 4 bytes	- bounding box max (x, y, z)
// 4 bytes		- components count in vertex declaration
// 4 bytes		- number of additional UVs
// 4 bytes		- size of vertex (in bytes)
// for each vertex component:
//		4 bytes	- size of a vertex component (in bytes)
//		4 bytes	- offset of a vertex component (in bytes)
// 4 bytes		- number of meshes
// for each mesh:
//		4 bytes	- offset of a mesh in index buffer (in bytes)
//		4 bytes	- number of indices in a mesh (in bytes)
// X bytes		- vertex buffer
// Y bytes		- index buffer

const unsigned int MAGIC_GEOM = 0x12345002;

#import "Mesh.h"
#include <vector>

@implementation Mesh
{
@private
  NSString * _path;
  id<MTLBuffer> _vertexBuffer;
  id<MTLBuffer> _indexBuffer;
  uint32_t _groupsCount;
  BOOL _isReady;
  simd::float3 _boundingBoxMin;
  simd::float3 _boundingBoxMax;
  uint32_t _vertexSize;
  std::vector<uint32_t> _offsets;
  std::vector<uint32_t> _indicesCountForGroups;
  uint32_t _verticesCount;
  uint32_t _indicesCount;
}

- (instancetype)initWithResourceName:(NSString *)name
{
  NSString * path = [[NSBundle mainBundle] pathForResource:name ofType:@"geom"];
  if (!path)
  {
    return nil;
  }
  self = [super init];
  if (self)
  {
    _path = path;
    _isReady = NO;
    _groupsCount = 0;
    _vertexBuffer = nil;
    _indexBuffer = nil;
    _vertexSize = 0;
    _verticesCount = 0;
    _indicesCount = 0;
    _boundingBoxMin = simd::float3{0, 0, 0};
    _boundingBoxMax = simd::float3{0, 0, 0};
  }

  return self;
}

- (void)dealloc
{
  _path = nil;
  _vertexBuffer = nil;
  _indexBuffer = nil;
  _isReady = NO;
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

- (BOOL)loadFromFileWithDevice:(id<MTLDevice>)device
{
  FILE * fp = 0;
  fp = fopen([_path UTF8String], "rb");
  if (!fp)
  {
    NSLog(@"Could not open file '%@'.", _path);
    return NO;
  }

  unsigned int magic = 0;
  fread(&magic, sizeof(magic), 1, fp);
  if (magic != MAGIC_GEOM)
  {
    NSLog(@"Unrecognized (or obsolete) format of geom-file '%@'.", _path);
    fclose(fp);
    return NO;
  }

  float fbuf[3] = {0, 0, 0};
  fread(&fbuf, sizeof(fbuf), 1, fp);
  float fbuf2[3] = {0, 0, 0};
  fread(&fbuf2, sizeof(fbuf2), 1, fp);
  _boundingBoxMin = simd::float3{fbuf[0], fbuf[1], fbuf[2]};
  _boundingBoxMax = simd::float3{fbuf2[0], fbuf2[1], fbuf2[2]};

  // vertex declaration
  unsigned int componentsCount = 0;
  fread(&componentsCount, sizeof(componentsCount), 1, fp);
  if (componentsCount != 5)
  {
    NSLog(@"A mesh has unsupported vertex declaration (only pos-norm-uv-tang-binorm supported).");
    fclose(fp);
    return NO;
  }
  unsigned int additionalUVsCount = 0;
  fread(&additionalUVsCount, sizeof(additionalUVsCount), 1, fp);
  if (additionalUVsCount != 0)
  {
    NSLog(@"A mesh has unsupported vertex declaration (the only uv channel supported)");
    fclose(fp);
    return NO;
  }
  fread(&_vertexSize, sizeof(_vertexSize), 1, fp);

  for (unsigned int c = 0; c < componentsCount; c++)
  {
    unsigned int vcs = 0;
    fread(&vcs, sizeof(vcs), 1, fp);
    unsigned int vco = 0;
    fread(&vco, sizeof(vco), 1, fp);
  }

  fread(&_groupsCount, sizeof(_groupsCount), 1, fp);
  if (_groupsCount == 0)
  {
    NSLog(@"There is no groups in '%@'.", _path);
    fclose(fp);
    return NO;
  }

  // groups
  _offsets.resize(_groupsCount);
  _indicesCountForGroups.resize(_groupsCount);
  for (unsigned int m = 0; m < _groupsCount; m++)
  {
    fread(&_offsets[m], sizeof(_offsets[m]), 1, fp);
    fread(&_indicesCountForGroups[m], sizeof(_indicesCountForGroups[m]), 1, fp);
  }

  // vertex buffer
  unsigned int vbsize = 0;
  fread(&vbsize, sizeof(vbsize), 1, fp);
  std::vector<unsigned char> vbuf;
  vbuf.resize(vbsize);
  fread(vbuf.data(), sizeof(unsigned char), vbsize, fp);
  _verticesCount = vbsize / _vertexSize;
  _vertexBuffer = [device newBufferWithBytes:(vbuf.data())
                                      length:vbsize
                                     options:MTLResourceOptionCPUCacheModeDefault];
  _vertexBuffer.label = @"Vertex buffer";

  // index buffer
  unsigned int ibsize = 0;
  fread(&ibsize, sizeof(ibsize), 1, fp);
  _indicesCount = ibsize / sizeof(unsigned int);
  std::vector<unsigned int> ibuf;
  ibuf.resize(_indicesCount);
  fread(ibuf.data(), sizeof(unsigned int), _indicesCount, fp);
  _indexBuffer = [device newBufferWithBytes:(ibuf.data())
                                     length:ibsize
                                    options:MTLResourceOptionCPUCacheModeDefault];
  _indexBuffer.label = @"Index buffer";

  fclose(fp);
  _isReady = YES;

  return YES;
}

- (uint32_t)indexBufferOffsetForGroup:(uint32_t)groupIndex
{
  if (groupIndex >= _groupsCount)
    return 0;
  return _offsets[groupIndex] * sizeof(unsigned int);
}

- (uint32_t)indicesCountForGroup:(uint32_t)groupIndex
{
  if (groupIndex >= _groupsCount)
    return 0;
  return _indicesCountForGroups[groupIndex];
}

- (void)drawGroup:(uint32_t)groupIndex WithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
  if (groupIndex >= _groupsCount)
    return;
  [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                            indexCount:_indicesCountForGroups[groupIndex]
                             indexType:MTLIndexTypeUInt32
                           indexBuffer:_indexBuffer
                     indexBufferOffset:_offsets[groupIndex] * sizeof(unsigned int)];
}

- (void)drawAllWithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
  for (uint32_t i = 0; i < _groupsCount; i++)
  {
    [self drawGroup:i WithEncoder:renderEncoder];
  }
}

- (void)drawGroup:(uint32_t)groupIndex
        Instances:(uint32_t)instances
      WithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
  if (groupIndex >= _groupsCount)
    return;
  [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                            indexCount:_indicesCountForGroups[groupIndex]
                             indexType:MTLIndexTypeUInt32
                           indexBuffer:_indexBuffer
                     indexBufferOffset:_offsets[groupIndex] * sizeof(unsigned int)
                         instanceCount:instances];
}

- (void)drawAllInstanced:(uint32_t)instances WithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
  for (uint32_t i = 0; i < _groupsCount; i++)
  {
    [self drawGroup:i Instances:instances WithEncoder:renderEncoder];
  }
}

@end

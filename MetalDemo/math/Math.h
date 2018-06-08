//
//  Math.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//
//  Borrowed from Apple Metal Samples
//  (https://developer.apple.com/library/ios/samplecode/MetalBasic3D/Introduction/Intro.html)

#ifndef _METAL_DEMO_MATH_H_
#define _METAL_DEMO_MATH_H_

#import <simd/simd.h>
#import "Quaternion.h"

#ifdef __cplusplus

namespace Math
{
float deg2Rad(const float & degrees);

simd::float4x4 scale(const float & x, const float & y, const float & z);
simd::float4x4 scale(const simd::float3 & s);

simd::float4x4 translate(const float & x, const float & y, const float & z);
simd::float4x4 translate(const simd::float3 & t);

simd::float4x4 rotate(const float & angle, const float & x, const float & y, const float & z);
simd::float4x4 rotate(const float & angle, const simd::float3 & u);

simd::float4x4 frustum(const float & fovH, const float & fovV, const float & near,
                       const float & far);

simd::float4x4 frustum(const float & left, const float & right, const float & bottom,
                       const float & top, const float & near, const float & far);

simd::float4x4 frustumOffCenter(const float & left, const float & right, const float & bottom,
                                const float & top, const float & near, const float & far);

simd::float4x4 lookAt(const float * const pEye, const float * const pCenter,
                      const float * const pUp);
simd::float4x4 lookAt(const simd::float3 & eye, const simd::float3 & center,
                      const simd::float3 & up);

simd::float4x4 perspective(const float & width, const float & height, const float & near,
                           const float & far);

simd::float4x4 perspectiveFov(const float & fovy, const float & aspect, const float & near,
                              const float & far);
simd::float4x4 perspectiveFov(const float & fovy, const float & width, const float & height,
                              const float & near, const float & far);

simd::float4x4 orthoOffCenter(const float & left, const float & right, const float & bottom,
                              const float & top, const float & near, const float & far);
simd::float4x4 orthoOffCenter(const simd::float3 & origin, const simd::float3 & size);

simd::float4x4 ortho(const float & left, const float & right, const float & bottom,
                     const float & top, const float & near, const float & far);
simd::float4x4 ortho(const simd::float3 & origin, const simd::float3 & size);
}  // namespace Math

#endif

#endif

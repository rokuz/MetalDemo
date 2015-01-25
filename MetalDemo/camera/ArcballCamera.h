//
//  ArcballCamera.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.

#ifndef _METAL_DEMO_ARCBALL_CAMERA_H_
#define _METAL_DEMO_ARCBALL_CAMERA_H_

#import <simd/simd.h>
#import "../math/Math.h"

#ifdef __cplusplus

class ArcballCamera
{
public:
    ArcballCamera();

    void startRotation(float xpos, float ypos);
    void updateRotation(float xpos, float ypos);
    void stopRotation();
    
    void startZooming(float d);
    void updateZooming(float d);
    void stopZooming();
    
    matrix_float4x4 getView();
    simd::float3 getCurrentViewPosition() const;
    
    simd::float2 getLastFingerPosition() const;
    bool isRotatingNow() const;
    bool isZoomingNow() const;
    
    void reset();
    
private:
    bool isRotating;
    simd::float2 lastFingerPosition;
    simd::float2 currentFingerPosition;
    simd::float2 angles;
    quaternion rotation;
    
    bool isZooming;
    float lastDistance;
    float currentDistance;
    
    simd::float3 currentViewPosition;
};

#endif

#endif

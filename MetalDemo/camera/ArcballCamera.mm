//
//  ArcballCamera.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.

#import "ArcballCamera.h"
#import "Math.h"
#import <cmath>

#include <algorithm>

#ifdef __cplusplus

const float ROTATION_SPEED = 0.25f;
const float MIN_ZOOM = 10.0f;
const float MAX_ZOOM = 120.0f;
const float ZOOM_SPEED = 0.025f;

ArcballCamera::ArcballCamera()
{
    isRotating = false;
    isZooming = false;
    lastFingerPosition = simd::float2 { 0, 0 };
    currentFingerPosition = simd::float2 { 0, 0 };
    currentDistance = 5;
    lastDistance = 0;
    reset();
}

void ArcballCamera::reset()
{
    currentViewPosition = simd::float3 { 0, 0, 0 };
    rotation.ident();
}

void ArcballCamera::init(float xangle, float yangle, float distance)
{
    currentDistance = distance;
    angles.x = xangle;
    angles.y = yangle;
    if (angles.y > 89.9f) angles.y = 89.9f;
    if (angles.y < -89.9) angles.y = -89.9f;
    
    quaternion q1;
    q1.set_rotate_axis_angle(simd::float3 { 0, 1, 0 }, Math::deg2Rad(angles.x));
    quaternion q2;
    q2.set_rotate_axis_angle(simd::float3 { 1, 0, 0 }, Math::deg2Rad(angles.y));
    rotation = q1 * q2;
}

void ArcballCamera::startRotation(float xpos, float ypos)
{
    if (isZooming || isRotating) return;
    
    lastFingerPosition = simd::float2 { xpos, ypos };
    currentFingerPosition = lastFingerPosition;
    
    isRotating = true;
}

void ArcballCamera::updateRotation(float xpos, float ypos)
{
    if (isRotating)
    {
        currentFingerPosition = simd::float2 { xpos, ypos };
    }
}

void ArcballCamera::stopRotation()
{
    isRotating = false;
}

void ArcballCamera::startZooming(float d)
{
    if (isRotating || isZooming) return;
    
    lastDistance = d;
    isZooming = true;
}

void ArcballCamera::updateZooming(float d)
{
    if (isZooming) {
        float delta = lastDistance - d;
        currentDistance += delta * ZOOM_SPEED;
        if (currentDistance < MIN_ZOOM) currentDistance = MIN_ZOOM;
        if (currentDistance > MAX_ZOOM) currentDistance = MAX_ZOOM;
        lastDistance = d;
    }
}

void ArcballCamera::stopZooming()
{
    isZooming = false;
}

void ArcballCamera::updateView()
{
    if (isRotating)
    {
        simd::float2 delta = currentFingerPosition - lastFingerPosition;
        if (fabs(delta.x) > 1e-5 || fabs(delta.y) > 1e-5)
        {
            simd::float2 old_angles = angles;
            angles.x += delta.x * ROTATION_SPEED;
            angles.y -= delta.y * ROTATION_SPEED;
            if (angles.y > 89.9f) angles.y = 89.9f;
            if (angles.y < -89.9) angles.y = -89.9f;
            
            if (fabs(old_angles.x - angles.x) > 1e-5 || fabs(old_angles.y - angles.y) > 1e-5)
            {
                quaternion q1;
                q1.set_rotate_axis_angle(simd::float3 { 0, 1, 0 }, Math::deg2Rad(angles.x));
                quaternion q2;
                q2.set_rotate_axis_angle(simd::float3 { 1, 0, 0 }, Math::deg2Rad(angles.y));
                rotation = q1 * q2;
            }
            lastFingerPosition = currentFingerPosition;
        }
    }
    
    simd::float3 v = rotation.z_direction();
    currentViewPosition = currentDistance * (simd::float3){v.x, v.y, v.z};
}

matrix_float4x4 ArcballCamera::getView() const
{
    return Math::lookAt(currentViewPosition, (simd::float3){0, 0, 0}, (simd::float3){0, 1, 0});
}

simd::float2 ArcballCamera::getLastFingerPosition() const
{
    return lastFingerPosition;
}

bool ArcballCamera::isRotatingNow() const
{
    return isRotating;
}

bool ArcballCamera::isZoomingNow() const
{
    return isZooming;
}

simd::float3 ArcballCamera::getCurrentViewPosition() const
{
    return currentViewPosition;
}

#endif

//
//  Quaternion.h
//  MetalDemo
//
//  Created by Roman Kuznetsov on 24.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#ifndef _METAL_DEMO_ARCBALL_QUATERNION_H_
#define _METAL_DEMO_ARCBALL_QUATERNION_H_

#import <cmath>
#import <simd/simd.h>

#ifdef __cplusplus

class quaternion
{
public:
    float x, y, z, w;
    
    quaternion(): x(0.0f), y(0.0f), z(0.0f), w(1.0f){}
    quaternion(float _x, float _y, float _z, float _w): x(_x), y(_y), z(_z), w(_w){}
    quaternion(const quaternion& q): x(q.x), y(q.y), z(q.z), w(q.w){}
    
    void set(float _x, float _y, float _z, float _w);
    void set(const quaternion& q);
    void ident();
    void conjugate();
    void scale(float s);
    float norm();
    
    float magnitude();
    void invert();
    void normalize();
    bool operator==(const quaternion& q);
    bool operator!=(const quaternion& q);
    
    const quaternion& operator+=(const quaternion& q);
    const quaternion& operator-=(const quaternion& q);
    const quaternion& operator*=(const quaternion& q);
    simd::float3 rotate(const simd::float3& v);
    simd::float3 z_direction() const;
    simd::float3 x_direction() const;
    simd::float3 y_direction() const;
    
    void set_rotate_axis_angle(const simd::float3& v, float a);
    void set_rotate_axis_cos_angle(const simd::float3& v, float cos_a);
    
    void set_rotate_x(float a);
    void set_rotate_y(float a);
    void set_rotate_z(float a);
    void set_rotate_xyz(float ax, float ay, float az);
    
    bool isequal(const quaternion& v, float tol) const;
    void slerp(const quaternion& q0, const quaternion& q1, float l);
    void lerp(const quaternion& q0, const quaternion& q1, float l);
};

extern quaternion operator+(const quaternion& q0, const quaternion& q1);
extern quaternion operator-(const quaternion& q0, const quaternion& q1);
extern quaternion operator*(const quaternion& q0, const quaternion& q1);

#endif

#endif

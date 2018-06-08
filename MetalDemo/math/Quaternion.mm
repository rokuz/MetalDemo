//
//  Quaternion.m
//  MetalDemo
//
//  Created by Roman Kuznetsov on 24.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#import "Quaternion.h"

#ifdef __cplusplus

void quaternion::set(float _x, float _y, float _z, float _w)
{
  x = _x;
  y = _y;
  z = _z;
  w = _w;
}
void quaternion::set(const quaternion & q)
{
  x = q.x;
  y = q.y;
  z = q.z;
  w = q.w;
}

void quaternion::ident()
{
  x = 0.0f;
  y = 0.0f;
  z = 0.0f;
  w = 1.0f;
}

void quaternion::conjugate()
{
  x = -x;
  y = -y;
  z = -z;
}

void quaternion::scale(float s)
{
  x *= s;
  y *= s;
  z *= s;
  w *= s;
}

float quaternion::norm() { return x * x + y * y + z * z + w * w; }

float quaternion::magnitude()
{
  float n = norm();
  if (n > 0.0f)
    return std::sqrt(n);
  else
    return 0.0f;
}

void quaternion::invert()
{
  float n = norm();
  if (n > 0.0f)
    scale(1.0f / norm());
  conjugate();
}

void quaternion::normalize()
{
  float l = magnitude();
  if (l > 0.0f)
    scale(1.0f / l);
  else
    set(0.0f, 0.0f, 0.0f, 1.0f);
}

bool quaternion::operator==(const quaternion & q)
{
  return ((x == q.x) && (y == q.y) && (z == q.z) && (w == q.w)) ? true : false;
}

bool quaternion::operator!=(const quaternion & q)
{
  return ((x != q.x) || (y != q.y) || (z != q.z) || (w != q.w)) ? true : false;
}

const quaternion & quaternion::operator+=(const quaternion & q)
{
  x += q.x;
  y += q.y;
  z += q.z;
  w += q.w;
  return *this;
}

const quaternion & quaternion::operator-=(const quaternion & q)
{
  x -= q.x;
  y -= q.y;
  z -= q.z;
  w -= q.w;
  return *this;
}

const quaternion & quaternion::operator*=(const quaternion & q)
{
  float qx = w * q.x + x * q.w + y * q.z - z * q.y;
  float qy = w * q.y + y * q.w + z * q.x - x * q.z;
  float qz = w * q.z + z * q.w + x * q.y - y * q.x;
  float qw = w * q.w - x * q.x - y * q.y - z * q.z;
  x = qx;
  y = qy;
  z = qz;
  w = qw;
  return *this;
}

simd::float3 quaternion::rotate(const simd::float3 & v)
{
  quaternion q(v.x * w + v.z * y - v.y * z, v.y * w + v.x * z - v.z * x,
               v.z * w + v.y * x - v.x * y, v.x * x + v.y * y + v.z * z);

  return simd::float3{w * q.x + x * q.w + y * q.z - z * q.y, w * q.y + y * q.w + z * q.x - x * q.z,
                      w * q.z + z * q.w + x * q.y - y * q.x};
}

simd::float3 quaternion::z_direction() const
{
  return simd::float3{2 * w * y + 2 * x * z, 2 * y * z - 2 * x * w, w * w + z * z - x * x - y * y};
}

simd::float3 quaternion::x_direction() const
{
  return simd::float3{w * w + x * x - y * y - z * z, 2 * w * z + 2 * y * x, 2 * x * z - 2 * y * w};
}

simd::float3 quaternion::y_direction() const
{
  return simd::float3{2 * y * x - 2 * z * w, w * w + y * y - z * z - x * x, 2 * z * y + 2 * x * w};
}

void quaternion::set_rotate_axis_angle(const simd::float3 & v, float a)
{
  float sin_a = std::sin(a * 0.5f);
  float cos_a = std::cos(a * 0.5f);
  x = v.x * sin_a;
  y = v.y * sin_a;
  z = v.z * sin_a;
  w = cos_a;
}

void quaternion::set_rotate_axis_cos_angle(const simd::float3 & v, float cos_a)
{
  cos_a = std::sqrt((1.0 + cos_a) * 0.5f);
  float sin_a = std::sqrt(1.0 - cos_a * cos_a);
  x = v.x * sin_a;
  y = v.y * sin_a;
  z = v.z * sin_a;
  w = cos_a;
}

void quaternion::set_rotate_x(float a)
{
  float sin_a = std::sin(a * 0.5f);
  float cos_a = std::cos(a * 0.5f);
  x = sin_a;
  y = 0.0f;
  z = 0.0f;
  w = cos_a;
}

void quaternion::set_rotate_y(float a)
{
  float sin_a = std::sin(a * 0.5f);
  float cos_a = std::cos(a * 0.5f);
  x = 0.0f;
  y = sin_a;
  z = 0.0f;
  w = cos_a;
}

void quaternion::set_rotate_z(float a)
{
  float sin_a = std::sin(a * 0.5f);
  float cos_a = std::cos(a * 0.5f);
  x = 0.0f;
  y = 0.0f;
  z = sin_a;
  w = cos_a;
}

void quaternion::set_rotate_xyz(float ax, float ay, float az)
{
  quaternion qx, qy, qz;
  qx.set_rotate_x(ax);
  qy.set_rotate_y(ay);
  qz.set_rotate_z(az);
  *this = qx;
  *this *= qy;
  *this *= qz;
}

bool quaternion::isequal(const quaternion & v, float tol) const
{
  if (fabs(v.x - x) > tol)
    return false;
  else if (fabs(v.y - y) > tol)
    return false;
  else if (fabs(v.z - z) > tol)
    return false;
  else if (fabs(v.w - w) > tol)
    return false;
  return true;
}

void quaternion::slerp(const quaternion & q0, const quaternion & q1, float l)
{
  float fScale1;
  float fScale2;
  quaternion A = q0;
  quaternion B = q1;

  // compute dot product, aka cos(theta):
  float fCosTheta = A.x * B.x + A.y * B.y + A.z * B.z + A.w * B.w;

  if (fCosTheta < 0.0f)
  {
    // flip start quaternion
    A.x = -A.x;
    A.y = -A.y;
    A.z = -A.z;
    A.w = -A.w;
    fCosTheta = -fCosTheta;
  }

  if ((fCosTheta + 1.0f) > 0.05f)
  {
    // If the quaternions are close, use linear interploation
    if ((1.0f - fCosTheta) < 0.05f)
    {
      fScale1 = 1.0f - l;
      fScale2 = l;
    }
    else
    {
      // Otherwise, do spherical interpolation
      float fTheta = std::acos(fCosTheta);
      float fSinTheta = std::sin(fTheta);
      fScale1 = std::sin(fTheta * (1.0f - l)) / fSinTheta;
      fScale2 = std::sin(fTheta * l) / fSinTheta;
    }
  }
  else
  {
    B.x = -A.y;
    B.y = A.x;
    B.z = -A.w;
    B.w = A.z;
    fScale1 = std::sin(M_PI * (0.5f - l));
    fScale2 = std::sin(M_PI * l);
  }

  x = fScale1 * A.x + fScale2 * B.x;
  y = fScale1 * A.y + fScale2 * B.y;
  z = fScale1 * A.z + fScale2 * B.z;
  w = fScale1 * A.w + fScale2 * B.w;
}

void quaternion::lerp(const quaternion & q0, const quaternion & q1, float l) { slerp(q0, q1, l); }

quaternion operator+(const quaternion & q0, const quaternion & q1)
{
  return quaternion(q0.x + q1.x, q0.y + q1.y, q0.z + q1.z, q0.w + q1.w);
}

quaternion operator-(const quaternion & q0, const quaternion & q1)
{
  return quaternion(q0.x - q1.x, q0.y - q1.y, q0.z - q1.z, q0.w - q1.w);
}

quaternion operator*(const quaternion & q0, const quaternion & q1)
{
  return quaternion(q0.w * q1.x + q0.x * q1.w + q0.y * q1.z - q0.z * q1.y,
                    q0.w * q1.y + q0.y * q1.w + q0.z * q1.x - q0.x * q1.z,
                    q0.w * q1.z + q0.z * q1.w + q0.x * q1.y - q0.y * q1.x,
                    q0.w * q1.w - q0.x * q1.x - q0.y * q1.y - q0.z * q1.z);
}

#endif

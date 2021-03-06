//
//  Math.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//
//  Borrowed from Apple Metal Samples
//  (https://developer.apple.com/library/ios/samplecode/MetalBasic3D/Introduction/Intro.html)

#import <cmath>

#ifdef __cplusplus

#import "Math.h"

namespace Math
{
float deg2Rad(const float & degrees) { return float(M_PI) * degrees / 180.0f; }

simd::float4x4 scale(const float & x, const float & y, const float & z)
{
  simd::float4 v = {x, y, z, 1.0f};
  return simd::float4x4(v);
}

simd::float4x4 scale(const simd::float3 & s)
{
  simd::float4 v = {s.x, s.y, s.z, 1.0f};
  return simd::float4x4(v);
}

simd::float4x4 translate(const simd::float3 & t)
{
  simd::float4x4 M = matrix_identity_float4x4;
  M.columns[3].xyz = t;
  return M;
}

simd::float4x4 translate(const float & x, const float & y, const float & z)
{
  return translate((simd::float3){x, y, z});
}

simd::float4x4 rotate(const float & angle, const simd::float3 & r)
{
  float a = angle / 180.0f;
  float c = 0.0f;
  float s = 0.0f;
  __sincospif(a, &s, &c);

  float k = 1.0f - c;

  simd::float3 u = simd::normalize(r);
  simd::float3 v = s * u;
  simd::float3 w = k * u;

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = w.x * u.x + c;
  P.y = w.x * u.y + v.z;
  P.z = w.x * u.z - v.y;
  P.w = 0.0f;

  Q.x = w.x * u.y - v.z;
  Q.y = w.y * u.y + c;
  Q.z = w.y * u.z + v.x;
  Q.w = 0.0f;

  R.x = w.x * u.z + v.y;
  R.y = w.y * u.z - v.x;
  R.z = w.z * u.z + c;
  R.w = 0.0f;

  S.x = 0.0f;
  S.y = 0.0f;
  S.z = 0.0f;
  S.w = 1.0f;

  return simd::float4x4(P, Q, R, S);
}

simd::float4x4 rotate(const float & angle, const float & x, const float & y, const float & z)
{
  simd::float3 r = {x, y, z};
  return rotate(angle, r);
}

simd::float4x4 perspective(const float & width, const float & height, const float & near,
                           const float & far)
{
  float zNear = 2.0f * near;
  float zFar = far / (far - near);

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = zNear / width;
  P.y = 0.0f;
  P.z = 0.0f;
  P.w = 0.0f;

  Q.x = 0.0f;
  Q.y = zNear / height;
  Q.z = 0.0f;
  Q.w = 0.0f;

  R.x = 0.0f;
  R.y = 0.0f;
  R.z = zFar;
  R.w = 1.0f;

  S.x = 0.0f;
  S.y = 0.0f;
  S.z = -near * zFar;
  S.w = 0.0f;

  return simd::float4x4(P, Q, R, S);
}

simd::float4x4 perspectiveFov(const float & fovy, const float & aspect, const float & near,
                              const float & far)
{
  float angle = deg2Rad(0.5f * fovy);
  float yScale = 1.0f / std::tan(angle);
  float xScale = yScale / aspect;
  float zScale = far / (far - near);

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = xScale;
  P.y = 0.0f;
  P.z = 0.0f;
  P.w = 0.0f;

  Q.x = 0.0f;
  Q.y = yScale;
  Q.z = 0.0f;
  Q.w = 0.0f;

  R.x = 0.0f;
  R.y = 0.0f;
  R.z = zScale;
  R.w = 1.0f;

  S.x = 0.0f;
  S.y = 0.0f;
  S.z = -near * zScale;
  S.w = 0.0f;

  return simd::float4x4(P, Q, R, S);
}

simd::float4x4 perspectiveFov(const float & fovy, const float & width, const float & height,
                              const float & near, const float & far)
{
  float aspect = width / height;
  return perspectiveFov(fovy, aspect, near, far);
}

simd::float4x4 lookAt(const simd::float3 & eye, const simd::float3 & center,
                      const simd::float3 & up)
{
  simd::float3 zAxis = simd::normalize(center - eye);
  simd::float3 xAxis = simd::normalize(simd::cross(up, zAxis));
  simd::float3 yAxis = simd::cross(zAxis, xAxis);

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = xAxis.x;
  P.y = yAxis.x;
  P.z = zAxis.x;
  P.w = 0.0f;

  Q.x = xAxis.y;
  Q.y = yAxis.y;
  Q.z = zAxis.y;
  Q.w = 0.0f;

  R.x = xAxis.z;
  R.y = yAxis.z;
  R.z = zAxis.z;
  R.w = 0.0f;

  S.x = -simd::dot(xAxis, eye);
  S.y = -simd::dot(yAxis, eye);
  S.z = -simd::dot(zAxis, eye);
  S.w = 1.0f;

  return simd::float4x4(P, Q, R, S);
}

simd::float4x4 lookAt(const float * const pEye, const float * const pCenter,
                      const float * const pUp)
{
  simd::float3 eye = {pEye[0], pEye[1], pEye[2]};
  simd::float3 center = {pCenter[0], pCenter[1], pCenter[2]};
  simd::float3 up = {pUp[0], pUp[1], pUp[2]};

  return lookAt(eye, center, up);
}

simd::float4x4 ortho(const float & left, const float & right, const float & bottom,
                     const float & top, const float & near, const float & far)
{
  float sLength = 1.0f / (right - left);
  float sHeight = 1.0f / (top - bottom);
  float sDepth = 1.0f / (far - near);

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = 2.0f * sLength;
  P.y = 0.0f;
  P.z = 0.0f;
  P.w = 0.0f;

  Q.x = 0.0f;
  Q.y = 2.0f * sHeight;
  Q.z = 0.0f;
  Q.w = 0.0f;

  R.x = 0.0f;
  R.y = 0.0f;
  R.z = sDepth;
  R.w = 0.0f;

  S.x = 0.0f;
  S.y = 0.0f;
  S.z = -near * sDepth;
  S.w = 1.0f;

  return simd::float4x4(P, Q, R, S);
}

simd::float4x4 ortho(const simd::float3 & origin, const simd::float3 & size)
{
  return ortho(origin.x, origin.y, origin.z, size.x, size.y, size.z);
}

simd::float4x4 orthoOffCenter(const float & left, const float & right, const float & bottom,
                              const float & top, const float & near, const float & far)
{
  float sLength = 1.0f / (right - left);
  float sHeight = 1.0f / (top - bottom);
  float sDepth = 1.0f / (far - near);

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = 2.0f * sLength;
  P.y = 0.0f;
  P.z = 0.0f;
  P.w = 0.0f;

  Q.x = 0.0f;
  Q.y = 2.0f * sHeight;
  Q.z = 0.0f;
  Q.w = 0.0f;

  R.x = 0.0f;
  R.y = 0.0f;
  R.z = sDepth;
  R.w = 0.0f;

  S.x = -sLength * (left + right);
  S.y = -sHeight * (top + bottom);
  S.z = -sDepth * near;
  S.w = 1.0f;

  return simd::float4x4(P, Q, R, S);
}

simd::float4x4 orthoOffCenter(const simd::float3 & origin, const simd::float3 & size)
{
  return orthoOffCenter(origin.x, origin.y, origin.z, size.x, size.y, size.z);
}

simd::float4x4 frustum(const float & fovH, const float & fovV, const float & near,
                       const float & far)
{
  float width = 1.0f / std::tan(deg2Rad(0.5f * fovH));
  float height = 1.0f / std::tan(deg2Rad(0.5f * fovV));
  float sDepth = far / (far - near);

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = width;
  P.y = 0.0f;
  P.z = 0.0f;
  P.w = 0.0f;

  Q.x = 0.0f;
  Q.y = height;
  Q.z = 0.0f;
  Q.w = 0.0f;

  R.x = 0.0f;
  R.y = 0.0f;
  R.z = sDepth;
  R.w = 1.0f;

  S.x = 0.0f;
  S.y = 0.0f;
  S.z = -sDepth * near;
  S.w = 0.0f;

  return simd::float4x4(P, Q, R, S);
}

simd::float4x4 frustum(const float & left, const float & right, const float & bottom,
                       const float & top, const float & near, const float & far)
{
  float width = right - left;
  float height = top - bottom;
  float depth = far - near;
  float sDepth = far / depth;

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = width;
  P.y = 0.0f;
  P.z = 0.0f;
  P.w = 0.0f;

  Q.x = 0.0f;
  Q.y = height;
  Q.z = 0.0f;
  Q.w = 0.0f;

  R.x = 0.0f;
  R.y = 0.0f;
  R.z = sDepth;
  R.w = 1.0f;

  S.x = 0.0f;
  S.y = 0.0f;
  S.z = -sDepth * near;
  S.w = 0.0f;

  return simd::float4x4(P, Q, R, S);
}

simd::float4x4 frustum_oc(const float & left, const float & right, const float & bottom,
                          const float & top, const float & near, const float & far)
{
  float sWidth = 1.0f / (right - left);
  float sHeight = 1.0f / (top - bottom);
  float sDepth = far / (far - near);
  float dNear = 2.0f * near;

  simd::float4 P;
  simd::float4 Q;
  simd::float4 R;
  simd::float4 S;

  P.x = dNear * sWidth;
  P.y = 0.0f;
  P.z = 0.0f;
  P.w = 0.0f;

  Q.x = 0.0f;
  Q.y = dNear * sHeight;
  Q.z = 0.0f;
  Q.w = 0.0f;

  R.x = -sWidth * (right + left);
  R.y = -sHeight * (top + bottom);
  R.z = sDepth;
  R.w = 1.0f;

  S.x = 0.0f;
  S.y = 0.0f;
  S.z = -sDepth * near;
  S.w = 0.0f;

  return simd::float4x4(P, Q, R, S);
}

}

#endif

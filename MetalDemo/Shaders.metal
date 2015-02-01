//
//  Shaders.metal
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

constant float3 lightDirection = float3(0.5, -0.7, -1.0);
constant float3 ambientColor = float3(0.1, 0.1, 0.1);
constant float3 specularColor = float3(0.3, 0.3, 0.3);
constant float specularPower = 30.0;

typedef struct
{
    float4x4 modelViewProjection;
    float4x4 model;
    float3 viewPosition;
} uniforms_t;

typedef struct
{
    packed_float3 position;
    packed_float3 normal;
    packed_float2 uv;
    packed_float3 tangent;
    packed_float3 binormal;
} vertex_t;

typedef struct
{
    float4 position [[position]];
    float2 uv;
    float3 tangent;
    float3 normal;
    float3 viewDirection;
} ColorInOut;

constexpr sampler trilinearSampler(address::clamp_to_zero, filter::linear, mip_filter::linear);

// Vertex shader function
vertex ColorInOut vsLighting(device vertex_t* vertex_array [[ buffer(0) ]],
                             constant uniforms_t& uniforms [[ buffer(1) ]],
                             unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
    float4 in_position = float4(float3(vertex_array[vid].position), 1.0);
    out.position = uniforms.modelViewProjection * in_position;
    
    float4x4 m = uniforms.model;
    m[3][0] = m[3][1] = m[3][2] = 0.0f; // suppress translation component
    out.normal = (m * float4(normalize(vertex_array[vid].normal), 1.0)).xyz;
    out.tangent = (m * float4(normalize(vertex_array[vid].tangent), 1.0)).xyz;
    
    float3 worldPos = (uniforms.model * in_position).xyz;
    out.viewDirection = normalize(worldPos - uniforms.viewPosition);
    
    out.uv = vertex_array[vid].uv;
    
    return out;
}

// Fragment shader function
fragment half4 psLighting(ColorInOut in [[stage_in]],
                          texture2d<half> diffuseTexture[[texture(0)]],
                          texture2d<half> normalTexture[[texture(1)]])
{
    float3 normalTS = (float3)normalize(normalTexture.sample(trilinearSampler, in.uv).rgb * 2.0 - 1.0);
    float3 lightDir = normalize(lightDirection);
    
    float3x3 ts = float3x3(in.tangent, cross(in.normal, in.tangent), in.normal);
    float3 normal = -normalize(ts * normalTS);
    float ndotl = fmax(0.0, dot(lightDir, normal));
    float3 color = (float3)diffuseTexture.sample(trilinearSampler, in.uv).rgb;
    float3 diffuse = color * ndotl;
    
    float3 h = normalize(in.viewDirection + lightDir);
    float3 specular = specularColor * pow(fmax(dot(normal, h), 0.0), specularPower);
    
    float3 finalColor = saturate(color * ambientColor + diffuse + specular);
    
    return half4(float4(finalColor, 1.0));
}

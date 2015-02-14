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
constant float3 ambientColor = float3(0.2, 0.2, 0.2);
constant float3 specularColor = float3(0.3, 0.3, 0.3);
constant float specularPower = 30.0;

typedef struct
{
    float4x4 viewProjection;
    float3 viewPosition;
} Uniforms_T;

typedef struct
{
    float4x4 model;
} InstanceUniforms_T;

typedef struct
{
    packed_float3 position;
    packed_float3 normal;
    packed_float2 uv;
    packed_float3 tangent;
    packed_float3 binormal;
} Vertex_T;

typedef struct
{
    float4 position [[position]];
    float2 uv;
    float3 tangent;
    float3 normal;
    float3 viewDirection;
} ColorInOut;

constexpr sampler trilinearSampler(address::clamp_to_zero, filter::linear, mip_filter::linear);

// Basic shading

vertex ColorInOut vsLighting(device Vertex_T* vertexArray [[ buffer(0) ]],
                             constant Uniforms_T& uniforms [[ buffer(1) ]],
                             constant InstanceUniforms_T* instanceUniforms [[ buffer(2) ]],
                             unsigned int vid [[ vertex_id ]],
                             ushort iid [[ instance_id ]])
{
    ColorInOut out;
    
    float4 in_position = float4(float3(vertexArray[vid].position), 1.0);
    float4x4 mvp = uniforms.viewProjection * instanceUniforms[iid].model;
    out.position = mvp * in_position;
    
    float4x4 m = instanceUniforms[iid].model;
    m[3][0] = m[3][1] = m[3][2] = 0.0f; // suppress translation component
    out.normal = (m * float4(normalize(vertexArray[vid].normal), 1.0)).xyz;
    out.tangent = (m * float4(normalize(vertexArray[vid].tangent), 1.0)).xyz;
    
    float3 worldPos = (instanceUniforms[iid].model * in_position).xyz;
    out.viewDirection = normalize(worldPos - uniforms.viewPosition);
    
    out.uv = vertexArray[vid].uv;
    
    return out;
}

fragment half4 psLighting(ColorInOut in [[stage_in]],
                          texture2d<half> diffuseTexture [[texture(0)]],
                          texture2d<half> normalTexture [[texture(1)]])
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

// Skybox

typedef struct
{
    float4x4 viewProjection;
} UniformsSkybox_T;

typedef struct
{
    packed_float3 position;
    packed_float3 normal;
    packed_float3 tangent;
} VertexSkybox_T;

typedef struct
{
    float4 position [[position]];
    float3 uv;
} SkyboxInOut;

vertex SkyboxInOut vsSkybox(device VertexSkybox_T* vertexArray [[ buffer(0) ]],
                            constant UniformsSkybox_T& uniforms [[ buffer(1) ]],
                            unsigned int vid [[ vertex_id ]])
{
    SkyboxInOut out;
    
    float4 in_position = float4(float3(vertexArray[vid].position), 1.0);
    out.position = uniforms.viewProjection * in_position;
    out.uv = float3(vertexArray[vid].position);
    
    return out;
}

fragment half4 psSkybox(SkyboxInOut in [[stage_in]],
                        texturecube<half> skyboxTexture [[texture(0)]])
{
    float3 c = saturate((float3)skyboxTexture.sample(trilinearSampler, in.uv).rgb);
    return half4(float4(c, 1.0));
}

//
//  Primitives.mm
//  MetalDemo
//
//  Created by Roman Kuznetsov on 23.01.15.
//  Copyright (c) 2015 rokuz. All rights reserved.
//

#ifdef __cplusplus

float cubeVertexData[] = {
    // position, normal, tangent
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,  -1.0, 0.0,  0.0,  -0.5, -0.5, 0.5,  0.0,  -1.0,
    0.0,  -1.0, 0.0,  0.0,  -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,  -1.0, 0.0,  0.0,  0.5,
    -0.5, -0.5, 0.0,  -1.0, 0.0,  -1.0, 0.0,  0.0,  0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
    -1.0, 0.0,  0.0,  -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,  -1.0, 0.0,  0.0,

    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  0.0,  0.0,  -1.0, 0.5,  -0.5, 0.5,  1.0,  0.0,
    0.0,  0.0,  0.0,  -1.0, 0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  0.0,  0.0,  -1.0, 0.5,
    0.5,  -0.5, 1.0,  0.0,  0.0,  0.0,  0.0,  -1.0, 0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
    0.0,  0.0,  -1.0, 0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,  0.0,  0.0,  -1.0,

    -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,  1.0,  0.0,  0.0,  0.5,  0.5,  0.5,  0.0,  1.0,
    0.0,  1.0,  0.0,  0.0,  0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,  1.0,  0.0,  0.0,  -0.5,
    0.5,  -0.5, 0.0,  1.0,  0.0,  1.0,  0.0,  0.0,  -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,
    1.0,  0.0,  0.0,  0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,  1.0,  0.0,  0.0,

    -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,  0.0,  0.0,  1.0,  -0.5, 0.5,  0.5,  -1.0, 0.0,
    0.0,  0.0,  0.0,  1.0,  -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,  0.0,  0.0,  1.0,  -0.5,
    -0.5, -0.5, -1.0, 0.0,  0.0,  0.0,  0.0,  1.0,  -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,
    0.0,  0.0,  1.0,  -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,  0.0,  0.0,  1.0,

    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0,  0.0,  0.0,  -0.5, 0.5,  0.5,  0.0,  0.0,
    1.0,  1.0,  0.0,  0.0,  -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,  1.0,  0.0,  0.0,  -0.5,
    -0.5, 0.5,  0.0,  0.0,  1.0,  1.0,  0.0,  0.0,  0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,
    1.0,  0.0,  0.0,  0.5,  0.5,  0.5,  0.0,  0.0,  1.0,  1.0,  0.0,  0.0,

    0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0, -1.0, 0.0,  0.0,  -0.5, -0.5, -0.5, 0.0,  0.0,
    -1.0, -1.0, 0.0,  0.0,  -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0, -1.0, 0.0,  0.0,  0.5,
    0.5,  -0.5, 0.0,  0.0,  -1.0, -1.0, 0.0,  0.0,  0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0,
    -1.0, 0.0,  0.0,  -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0, -1.0, 0.0,  0.0,
};

namespace Primitives
{
float * cube() { return cubeVertexData; }

unsigned int cubeSizeInBytes() { return sizeof(cubeVertexData); }

unsigned int cubeVertexSizeInBytes() { return 6 * sizeof(float); }
}

#endif

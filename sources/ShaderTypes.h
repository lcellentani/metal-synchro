#ifndef _ShaderTypes_H_
#define _ShaderTypes_H_

#include <simd/simd.h>

typedef enum {
    VertexInputLocationPosition = 0,
    VertexInputLocationViewportSize = 1
} VertexInputLocation;

typedef struct {
    vector_float2 position;
    vector_float4 color;
} PositionColorVertexFormat;

#endif

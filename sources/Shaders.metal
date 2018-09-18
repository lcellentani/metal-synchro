#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#import "ShaderTypes.h"

typedef struct {
    float4 clipSpacePosition [[position]];
    float4 color;
} RasterizerData;

vertex RasterizerData vertexShader(uint vertexID [[ vertex_id ]], device PositionColorVertexFormat *vertices [[ buffer(VertexInputLocationPosition) ]], constant vector_uint2 *viewportSizePointer [[ buffer(VertexInputLocationViewportSize) ]]) {
    RasterizerData out;
    
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
  
    float2 pixelSpacePosition = vertices[vertexID].position.xy;
    
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.color = vertices[vertexID].color;
    
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
    return in.color;
}

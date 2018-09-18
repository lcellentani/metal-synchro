#import <Foundation/Foundation.h>
#import <simd/simd.h>

#import "ShaderTypes.h"

@interface Sprite : NSObject

@property (nonatomic) vector_float2 position;
@property (nonatomic) vector_float4 color;

+ (const PositionColorVertexFormat *) vertices;
+ (NSUInteger) verticesCount;

@end

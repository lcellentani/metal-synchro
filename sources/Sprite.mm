#import "Sprite.h"

@implementation Sprite

+ (const PositionColorVertexFormat*) vertices {
    const float cSpriteSize = 5;
    static const PositionColorVertexFormat spriteVertices[] = {
        { { -cSpriteSize,   cSpriteSize },   { 0, 0, 0, 1 } },
        { {  cSpriteSize,   cSpriteSize },   { 0, 0, 0, 1 } },
        { { -cSpriteSize,  -cSpriteSize },   { 0, 0, 0, 1 } },
        
        { {  cSpriteSize,  -cSpriteSize },   { 0, 0, 0, 1 } },
        { { -cSpriteSize,  -cSpriteSize },   { 0, 0, 0, 1 } },
        { {  cSpriteSize,   cSpriteSize },   { 0, 0, 1, 1 } },
    };
    
    return spriteVertices;
}

+ (NSUInteger) verticesCount {
    return 6;
}

@end

#pragma once

#include "vec3.h"

namespace boids {

struct Boid final {
    Boid(float px0, float py0, float vx0, float vy0, float dx, float dy, float angle)
        : mPosition(vec3(px0, py0, 0.0f))
        , mVelocity(vec3(vx0, vy0, 0.0f))
        , mDirection(vec3(dx, dy, 0.0))
        , mAngle(angle) {
            
    }
    
    vec3 mPosition;
    vec3 mVelocity;
    
    vec3 mDirection;
    float mAngle;
};

} // namespace boids

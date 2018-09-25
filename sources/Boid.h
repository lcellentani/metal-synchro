#pragma once

#include "vec3.h"

namespace boids {

struct Boid {
    Boid(const vec3& p, const vec3& v) : mPosition(p), mVelocity(v) {}
    
    vec3 mPosition;
    vec3 mVelocity;
    vec3 mAcceleration;
};

} // namespace boids

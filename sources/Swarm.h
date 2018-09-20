#pragma once

#include <cstdint>
#include <vector>

#include "Boid.h"
#include "vec3.h"

namespace boids {

class Swarm {
public:
    void SetBounds(uint32_t width, uint32_t height);
    
    void Simulate(std::vector<Boid>& boids, float time);
    
private:
    uint32_t mBoundsWidth;
    uint32_t mBoundsHeight;
};
    
} // namespace boids

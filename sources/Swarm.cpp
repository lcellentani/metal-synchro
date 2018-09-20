#include "Swarm.h"

#include <math.h>

namespace boids {

void Swarm::SetBounds(uint32_t width, uint32_t height) {
    mBoundsWidth = width;
    mBoundsHeight = height;
}

void Swarm::Simulate(std::vector<Boid>& boids, float time) {
    if (boids.empty()) {
        return;
    }
    
    for(auto& boid : boids) {
        auto position = boid.mPosition;
        auto velocity = boid.mVelocity;
        auto direction = boid.mDirection;
        
        float angle = boid.mAngle / 180.0 * M_PI;
        
        float x = position.x() + ((time * velocity.x() * cosf(angle)) * direction.x());
        float y = position.y() + ((time * velocity.y() * sinf(angle)) * direction.y());
        
        if (x < 0) {
            x = 0;
            direction.x() = -direction.x();
        }
        if (x > mBoundsWidth) {
            x = mBoundsWidth;
            direction.x() = -direction.x();
        }
        if (y < 0) {
            y = 0;
            direction.y() = -direction.y();
        }
        if (y > mBoundsHeight) {
            y = mBoundsHeight;
            direction.y() = -direction.y();
        }
        
        boid.mPosition.x() = x;
        boid.mPosition.y() = y;
        boid.mDirection = direction;
    }
}

} // namespace boids

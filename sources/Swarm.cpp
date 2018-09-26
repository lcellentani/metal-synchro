#include "Swarm.h"
#include "rand.h"

#include <math.h>

namespace {
    
vec3 GetRandomUniform() {
    float theta = boids::random::get(0.0f, static_cast<float>(M_PI) * 2.0f);
    float r = std::sqrt(boids::random::get(0.0f, 1.0f));
    float z = std::sqrt(1.0f - r * r) * (boids::random::get(0.0f, 1.0f) > 0.5f ? -1.0f : 1.0f);
    return vec3(r * cos(theta), r * sin(theta), z);
}

float TransformDistance(float distance, boids::Swarm::DistanceType type) {
    if (type == boids::Swarm::DistanceType::Linear) {
        return distance;
    } else if (type == boids::Swarm::DistanceType::InverseLinear) {
        return distance == 0 ? 0 : 1 / distance;
    } else if (type == boids::Swarm::DistanceType::Quadratic) {
        return std::pow(distance, 2);
    } else if (type == boids::Swarm::DistanceType::InverseQuadratic) {
        float quad = std::pow(distance, 2);
        return quad == 0 ? 0 : 1 / quad;
    }
    return distance;
}
    
}

namespace boids {

void Swarm::Simulate(float time) {
    if (mEntities.empty()) {
        return;
    }
    
    if (mPerceptionRadius == 0) {
        mPerceptionRadius = 1;
    }
    
    BuildVoxelCache();
    
    for (auto& b : mEntities) {
        UpdateBoid(b);
    }
    
    for (auto& b : mEntities) {
        b.mVelocity = (b.mVelocity + b.mAcceleration * time).clampLength(mMaxVelocity);
        b.mPosition += b.mVelocity * time;
    }
}
    
void Swarm::BuildVoxelCache() {
    mVoxelCache.clear();
    mVoxelCache.reserve(mEntities.size());
    for (auto& boid : mEntities) {
        mVoxelCache[GetVoxelForBoid(boid)].push_back(&boid);
    }
}
    
void Swarm::UpdateBoid(Boid& boid) {
    vec3 separationSum;
    vec3 headingSum;
    vec3 positionSum;
    
    auto nearby = GetNearbyBoids(boid);
    
    for (NearbyBoid& closeBoid : nearby) {
        if (closeBoid.mDistance == 0.0f) {
            separationSum += GetRandomUniform() * 1000.0f;
        } else {
            float separationFactor = TransformDistance(closeBoid.mDistance, mSeparationType);
            separationSum += closeBoid.mDirection.negate() * separationFactor;
        }
        headingSum += closeBoid.mBoid->mVelocity;
        positionSum += closeBoid.mBoid->mPosition;
    }
    
    auto steeringTarget = boid.mPosition;
    float targetDistance = -1.0f;
    for (auto& target : mSteeringTargets) {
        float distance = TransformDistance(target.distanceTo(boid.mPosition), mSteeringTargetType);
        if (targetDistance < 0.0f || distance < targetDistance) {
            steeringTarget = target;
            targetDistance = distance;
        }
    }
    
    auto nearbySize = nearby.size();
    
    // Separation: steer to avoid crowding local flockmates
    vec3 separation = nearbySize > 0 ? separationSum / nearbySize : separationSum;
    
    // Alignment: steer towards the average heading of local flockmates
    vec3 alignment = nearbySize > 0 ? headingSum / nearbySize : headingSum;
    
    // Cohesion: steer to move toward the average position of local flockmates
    vec3 avgPosition = nearbySize > 0 ? positionSum / nearbySize : boid.mPosition;
    vec3 cohesion = avgPosition - boid.mPosition;
    
    // Steering: steer towards the nearest target location (like a moth to the light)
    vec3 steering = (steeringTarget - boid.mPosition).normalized() * targetDistance;
    
    // calculate boid acceleration
    vec3 acceleration;
    acceleration += separation * mSeparationWeight;
    acceleration += alignment * mAlignmentWeight;
    acceleration += cohesion * mCohesionWeight;
    acceleration += steering * mSteeringWeight;
    boid.mAcceleration = acceleration.clampLength(mMaxAcceleration);
}
    
std::vector<NearbyBoid> Swarm::GetNearbyBoids(const Boid& boid) const {
    std::vector<NearbyBoid> result;
    
    auto voxelPosition = GetVoxelForBoid(boid);
    voxelPosition -= 1.0f;
    for (int32_t x = 0; x < 4; x++) {
        for (int32_t y = 0; y < 4; y++) {
            for (int32_t z = 0; z < 4; z++) {
                CheckVoxelForBoids(boid, result, voxelPosition);
                voxelPosition.z()++;
            }
            voxelPosition.z() -= 4;
            voxelPosition.y()++;
        }
        voxelPosition.y() -= 4;
        voxelPosition.x()++;
    }
    return result;
}

vec3 Swarm::GetVoxelForBoid(const Boid& boid) const {
    float ir = 1.0 / std::abs(std::max(mPerceptionRadius, 1.0f));
    auto& p = boid.mPosition;
    return vec3(int(p.x() * ir), int(p.y() * ir), int(p.z() * ir));
}
    
void Swarm::CheckVoxelForBoids(const Boid& boid, std::vector<NearbyBoid>& result, const vec3& voxelPosition) const {
    (void)boid; (void)result; (void)voxelPosition;
    auto found = mVoxelCache.find(voxelPosition);
    if (found != mVoxelCache.end()) {
        for (auto test : found->second) {
            const auto& p1 = boid.mPosition;
            const auto& p2 = test->mPosition;
            vec3 diff = p2 - p1;
            float distance = diff.length();
            float blindAngle = boid.mVelocity.negate().angleTo(diff);
            if ((&boid) != test && distance <= mPerceptionRadius && (mBlindspotAngleDeg <= blindAngle || boid.mVelocity.length() == 0)) {
                NearbyBoid nb;
                nb.mBoid = test;
                nb.mDistance = distance;
                nb.mDirection = diff;
                result.push_back(nb);
            }
        }
    }
}
    
} // namespace boids

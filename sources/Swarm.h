#pragma once

#include <cstdint>
#include <vector>
#include <unordered_map>

#include "Boid.h"
#include "vec3.h"

namespace boids {
  
struct NearbyBoid {
    Boid* mBoid;
    vec3 mDirection;
    float mDistance;
};

class Swarm {
public:
    enum class DistanceType : uint8_t {
        Linear,
        InverseLinear,
        Quadratic,
        InverseQuadratic
    };
    
    Swarm(std::vector<Boid>& boids) : mEntities(boids) {}
    
    void SetBounds(uint32_t width, uint32_t height);
    
    void AddSteeringTarget(const vec3& target) {
        mSteeringTargets.emplace_back(target);
    }
    
    void Simulate(float time);
    
private:
    void BuildVoxelCache();
    void UpdateBoid(Boid& boid);
    std::vector<NearbyBoid> GetNearbyBoids(const Boid& boid) const;
    vec3 GetVoxelForBoid(const Boid& boid) const;
    void CheckVoxelForBoids(const Boid& boid, std::vector<NearbyBoid>& result, const vec3& voxelPosition) const;
    
    uint32_t mBoundsWidth;
    uint32_t mBoundsHeight;
    
    float mPerceptionRadius = 30.f;
    
    float mBlindspotAngleDeg = 20.f;
    float mMaxAcceleration = 100.f;
    float mMaxVelocity = 200.f;
    float mAlignmentWeight = 1.0f;
    float mCohesionWeight = 1.0f;
    
    std::vector<Boid>& mEntities;
    std::unordered_map<vec3, std::vector<Boid*>> mVoxelCache;
    
    float mSeparationWeight = 1.0f;
    DistanceType mSeparationType = DistanceType::InverseQuadratic;
    
    float mSteeringWeight = 0.1f;
    std::vector<vec3> mSteeringTargets;
    DistanceType mSteeringTargetType = DistanceType::Linear;
};
    
} // namespace boids

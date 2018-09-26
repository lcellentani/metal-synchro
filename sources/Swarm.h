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
    
    void AddSteeringTarget(const vec3& target) {
        mSteeringTargets.emplace_back(target);
    }
    std::size_t GetSteeringTargetsCount() const { return mSteeringTargets.size(); }
    vec3 GetSteeringTargetAtIndex(std::size_t index) const {
        if (index < mSteeringTargets.size()) {
            return mSteeringTargets[index];
        }
        return vec3();
    }
    
    void Simulate(float time);
    
    float GetMaximumVelocity() const { return mMaxVelocity;}
    void SetMaximumVelocity(float velocity) { mMaxVelocity = velocity; }
    
    float GetMaximumAcceleration() const { return mMaxAcceleration; }
    void SetMaximumAcceleration(float acceleration) { mMaxAcceleration = acceleration; }
    
    float GetSteeringWeight() const { return mSteeringWeight; }
    void SetSteeringWeight(float weight) { mSteeringWeight = weight; }
    
    float GetSeparationWeight() const { return mSeparationWeight; }
    void SetSeparationWeight(float weight) { mSeparationWeight = weight; }
    
    float GetCohesionWeight() const { return mCohesionWeight; }
    void SetChoesionWeight(float weight) { mCohesionWeight = weight; }
    
    float GetAlignmentWeight() const { return mAlignmentWeight; }
    void SetAlignmentWeight(float weight) { mAlignmentWeight = weight; }
    
private:
    void BuildVoxelCache();
    void UpdateBoid(Boid& boid);
    std::vector<NearbyBoid> GetNearbyBoids(const Boid& boid) const;
    vec3 GetVoxelForBoid(const Boid& boid) const;
    void CheckVoxelForBoids(const Boid& boid, std::vector<NearbyBoid>& result, const vec3& voxelPosition) const;
    
    float mPerceptionRadius = 30.f;
    
    float mBlindspotAngleDeg = 20.f;
    float mMaxAcceleration = 10.f;
    float mMaxVelocity = 20.f;
    float mAlignmentWeight = 1.0f;
    float mCohesionWeight = 1.0f;
    
    std::vector<Boid>& mEntities;
    std::unordered_map<vec3, std::vector<Boid*>> mVoxelCache;
    
    float mSeparationWeight = 1.0f;
    DistanceType mSeparationType = DistanceType::InverseQuadratic;
    
    float mSteeringWeight = 0.5f;
    std::vector<vec3> mSteeringTargets;
    DistanceType mSteeringTargetType = DistanceType::Linear;
};
    
} // namespace boids

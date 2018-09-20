#pragma once

#include <cmath>
#include <cstdlib>

class vec3 {
public:
	vec3() = default;
	vec3(float e0, float e1, float e2) {
		mData[0] = e0; mData[1] = e1; mData[2] = e2;
	}
	vec3(const vec3& other) {
		mData[0] = other.mData[0];
		mData[1] = other.mData[1];
		mData[2] = other.mData[2];
	}
	vec3(float scalar) {
		mData[0] = mData[1] = mData[2] = scalar;
	}

	vec3& operator=(const vec3& other) {
		if (&other != this) {
			mData[0] = other.mData[0];
			mData[1] = other.mData[1];
			mData[2] = other.mData[2];
		}
		return *this;
	}

	float x() const { return mData[0]; }
	float& x() { return mData[0]; };
	float y() const { return mData[1]; }
	float& y() { return mData[1]; }
	float z() const { return mData[2]; };
	float& z() { return mData[2]; }

	float r() const { return mData[0]; }
	float& r() { return mData[0]; };
	float g() const { return mData[1]; }
	float& g() { return mData[1]; }
	float b() const { return mData[2]; };
	float& b() { return mData[2]; }

	float operator[](size_t i) const { return mData[i]; }
	float& operator[](size_t i) { return mData[i]; }

	float length() const {
		return std::sqrt(mData[0] * mData[0] + mData[1] * mData[1] + mData[2] * mData[2]);
	}

	float lengthSquared() const {
		return mData[0] * mData[0] + mData[1] * mData[1] + mData[2] * mData[2];
	}

	vec3& normalize() {
		float il = 1.0f / length();
		mData[0] *= il;
		mData[1] *= il;
		mData[2] *= il;
		return *this;
	}

	vec3 normalized() const {
		vec3 result(*this);
		return result / result.length();
	}

	const vec3& operator+() const { return *this; }
	vec3 operator-() const { return vec3(-mData[0], -mData[1], -mData[2]); }

	vec3 operator+(const vec3& other) {
		return vec3(*this) += other;
	}
	vec3 operator+(const vec3& other) const {
		vec3 result(*this);
		result.mData[0] += other.mData[0];
		result.mData[1] += other.mData[1];
		result.mData[2] += other.mData[2];
		return result;
	}

	vec3 operator-(const vec3& other) {
		return vec3(*this) -= other;
	}
	vec3 operator-(const vec3& other) const {
		vec3 result(*this);
		result.mData[0] -= other.mData[0];
		result.mData[1] -= other.mData[1];
		result.mData[2] -= other.mData[2];
		return result;
	}

	vec3& operator+=(const vec3& other) {
		mData[0] += other.mData[0];
		mData[1] += other.mData[1];
		mData[2] += other.mData[2];
		return *this;
	}
	vec3& operator-=(const vec3& other) {
		mData[0] -= other.mData[0];
		mData[1] -= other.mData[1];
		mData[2] -= other.mData[2];
		return *this;
	}
	vec3& operator*=(const vec3& other) {
		mData[0] *= other.mData[0];
		mData[1] *= other.mData[1];
		mData[2] *= other.mData[2];
		return *this;
	}
	vec3& operator/=(const vec3& other) {
		mData[0] /= other.mData[0];
		mData[1] /= other.mData[1];
		mData[2] /= other.mData[2];
		return *this;
	}

	vec3& operator*=(const float scalar) {
		mData[0] *= scalar;
		mData[1] *= scalar;
		mData[2] *= scalar;
		return *this;
	}

	vec3& operator/=(const float scalar) {
		float k = 1.0f / scalar;
		mData[0] *= k;
		mData[1] *= k;
		mData[2] *= k;
		return *this;
	}
		
	friend vec3 operator*(const vec3& v1, const vec3& v2) {
		return vec3(v1[0] * v2[0], v1[1] * v2[1], v1[2] * v2[2]);
	}

	friend vec3 operator*(const vec3& v, float scalar) {
		vec3 result(v);
		result[0] *= scalar;
		result[1] *= scalar;
		result[2] *= scalar;
		return result;
	}
	friend vec3 operator*(float scalar, const vec3& v) {
		return v * scalar;
	}

	friend vec3 operator/(const vec3& v, float scalar) {
		vec3 result(v);
		float k = 1.0f / scalar;
		result[0] *= k;
		result[1] *= k;
		result[2] *= k;
		return result;
	}
	friend vec3 operator/(float scalar, const vec3& v) {
		return v / scalar;
	}

	static float dot(const vec3& v1, const vec3& v2) {
		return (v1.mData[0] * v2.mData[0]) + (v1.mData[1] * v2.mData[1]) + (v1.mData[2] * v2.mData[2]);
	}

	static vec3 cross(const vec3& v1, const vec3& v2) {
		return vec3(
			(v1.mData[1] * v2.mData[2] - v1.mData[2] * v2.mData[1]),
			-(v1.mData[0] * v2.mData[2] - v1.mData[2] * v2.mData[0]),
			(v1.mData[0] * v2.mData[1] - v1.mData[1] * v2.mData[0])
		);
	}

private:
	float mData[3]{ 0.0f };
};

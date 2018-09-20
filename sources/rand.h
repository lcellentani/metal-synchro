#pragma once

#include <random>
#include <limits>
#include <type_traits>

namespace boids {

namespace details
{

	template<typename T>
	struct is_integer {
		static constexpr bool value =
			std::is_same<T, short>::value ||
			std::is_same<T, int>::value ||
			std::is_same<T, long>::value ||
			std::is_same<T, long long>::value ||
			std::is_same<T, unsigned short>::value ||
			std::is_same<T, unsigned int>::value ||
			std::is_same<T, unsigned long>::value ||
			std::is_same<T, unsigned long long>::value;
	};

	template<typename T>
	struct is_real {
		static constexpr bool value =
			std::is_same<T, float>::value ||
			std::is_same<T, double>::value ||
			std::is_same<T, long double>::value;
	};
} // namespace detail 

template<typename E, typename S>
class random_class {
public:
	random_class() = delete;

	using engine_type = E;
	using seeder_type = S;

	template<typename T>
	static typename std::enable_if<details::is_integer<T>::value, T>::type get(T from = std::numeric_limits<T>::min(), T to = std::numeric_limits<T>::max()) {
		if (from > to) {
			return std::uniform_int_distribution<T>{ to, from }(engine_instance());
		}
		return std::uniform_int_distribution<T>{ from, to }(engine_instance());
	}

	template<typename T>
	static typename std::enable_if<details::is_real<T>::value, T>::type get(T from = std::numeric_limits<T>::min(), T to = std::numeric_limits<T>::max()) {
		if (from > to) {
			return std::uniform_real_distribution<T>{ to, from }(engine_instance());
		}
		return std::uniform_real_distribution<T>{ from, to }(engine_instance());
	}

private:
	static E& engine_instance() {
		S seeder{};
		static E engine{ seeder() };
		return engine;
	}
};

using random = random_class<std::mt19937, std::random_device>;
    
} // namespace boids


#include "waves.glsl"

#define PoM

vec3 getParallax(in vec3 world, in vec3 view) {
    const int steps = 8;

    const float height = 3.35/steps;

    view.xy = view.xy * steps / length(view) * height;

    float waveHeight = water_calculateWaves(world) * height;

    for(int i = 0; i < steps; ++i) {
    	world.xz = waveHeight * view.xy - world.xz;

    	waveHeight = water_calculateWaves(world) * height;
    }

    return world;
}

vec3 water_calculateParallax(vec3 pos, vec3 direction) {
	const int steps = 4;

	vec3  interval = 0.1 * direction / abs(direction.y);
	vec3  offset   = vec3(0.0, 0.0, 0.0);
	float height   = water_calculateWaves(pos);

	for (float i = 0.0; i < steps && height < offset.y; i++) {
		offset = (offset.y - height) * interval + offset;
		height = water_calculateWaves(vec3(offset.x, 0.0, offset.z) + pos);
	}

	return vec3(1.0, 0.0, 1.0) * offset + pos;
}

vec3 waterNormals(vec3 position, in vec3 view, in float dist) {
	#ifndef Deferred
    #ifdef PoM
	vec3 newPos = water_calculateParallax(position, normalize(view.xyz));
    #else
    vec3 newPos = position;
    #endif
	#else
    vec3 newPos = position;
	#endif
	vec2 diffs = vec2(water_calculateWaves(newPos + vec3(dist, 0.0, -dist)), water_calculateWaves(newPos + vec3(-dist, 0.0, dist))) - water_calculateWaves(newPos - vec3(dist, 0.0, dist));
	diffs *= 6.0;
	vec3 wavenormal = vec3(diffs, sqrt(1.0 - dot(diffs, diffs)));

	//wavenormal = mix(vec3(0.0, 0.0, 1.0), wavenormal, clamp(-view.y, 0.0, 0.25));

	return normalize(wavenormal);
}

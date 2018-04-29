#include "waves.glsl"

vec3 getParallax(in vec3 world, in vec3 view) {
    const int steps = 8;

    const float height = 4.35/steps;

    view.xy = view.xy * steps / length(view) * 4.35/steps;

    float waveHeight = waterHeight(world) * height;

    for(int i = 0; i < steps; ++i) {
    	world.xz = waveHeight * view.xy - world.xz;

    	waveHeight = waterHeight(world) * height;
    }

    return world;
}

vec3 waterNormals(vec3 position, in vec3 view) {
	float dist = 0.75;
	vec3 newPos = getParallax(position, normalize(view.xyz));
	vec2 diffs = vec2(waterHeight(newPos + vec3(dist, 0.0, -dist)), waterHeight(newPos + vec3(-dist, 0.0, dist))) - waterHeight(newPos - vec3(dist, 0.0, dist));
	diffs *= 1.0;
	return normalize(vec3(diffs, sqrt(1.0 - dot(diffs, diffs))));
}
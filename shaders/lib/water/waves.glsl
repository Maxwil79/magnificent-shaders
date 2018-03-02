#include "waterwaves.glsl"

#define ParallaxWaveSamples 8
#define PARALLAX_DEPTH 1.3

vec3 parallax_calculateCoordinate(vec3 inPosition, vec3 viewVector) {
	viewVector = normalize(viewVector);
    vec3 position = vec3(inPosition.x, 0.0, inPosition.z);
    viewVector *= vec3(PARALLAX_DEPTH, 1.0, PARALLAX_DEPTH) * 0.05;

    for (int i = 0; i < ParallaxWaveSamples && position.y > getWaves(vec3(position.x, inPosition.y, position.z)); i++, position += viewVector);

    return vec3(position.x, inPosition.y, position.z);
}

vec3 getParallax(in vec3 world, in vec3 view) {
    const int steps = ParallaxWaveSamples;

    const float height = PARALLAX_DEPTH;

    view.xy = view.xy * steps / length(view) * PARALLAX_DEPTH;

    float waveHeight = getWaves(world) * height;

    for(int i = 0; i < steps; ++i) {
    	world.xz = waveHeight * view.xy - world.xz;

    	waveHeight = getWaves(world) * height;
    }

    return world;
}

vec3 waterNormal(in vec3 world, in vec3 view) {
	const float sampleDist = 0.075;
	#ifdef WavePOM
	vec3 newWorld = getParallax(world, normalize(view.xyz));
	#else
	vec3 newWorld = world;
	#endif
	vec2 heightDiffs = vec2(getWaves(vec3(sampleDist,0.0,-sampleDist) + newWorld), getWaves(vec3(-sampleDist,0.0,sampleDist) + newWorld)) - getWaves(vec3(-sampleDist,0.0,-sampleDist) + newWorld);

	vec3 waterNormal = vec3(-2.0 * sampleDist, -2.0 * (sampleDist * sampleDist + sampleDist), 4.0 * sampleDist * sampleDist);
	waterNormal.xy *= heightDiffs;
	waterNormal = normalize(waterNormal);

	return tbn * waterNormal;
}
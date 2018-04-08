#include "waterwaves.glsl"

#define ParallaxWaveSamples 4
#define PARALLAX_DEPTH 1.3

vec3 parallax_calculateCoordinate(vec3 inPosition, vec3 viewVector) {
	viewVector = normalize(viewVector);
    vec3 position = vec3(inPosition.x, 0.0, inPosition.z);
    viewVector *= vec3(PARALLAX_DEPTH, 1.0, PARALLAX_DEPTH) * 0.05;

    for (int i = 0; i < ParallaxWaveSamples && position.y > getWaves(vec3(position.x, inPosition.y, position.z)); i++, position += viewVector);

    return vec3(position.x, inPosition.y, position.z);
}

vec3 getWaveParallax(
	in vec3 position,
	in vec3 direction
) {
	const vec3 stepSize = vec3(0.25);

	vec3 interval = direction * stepSize;

	// Scale up interval based on angle relative to surface
	interval /= abs(direction.z);

	// Start state
	float foundHeight = getWaves(position);
	vec3 offset = vec3(0.0, 0.0, 0.0);

	for(int i = 0; offset.z > foundHeight && i < 16; i++)
	{
		offset += mix(vec3(0.0), interval, pow(offset.z - foundHeight, 0.8));

		foundHeight = getWaves(position + vec3(offset.x, 0.0, offset.y));
	}

	return position + vec3(offset.x, 0.0, offset.y);
}

vec3 getParallax(in vec3 world, in vec3 view) {
    const int steps = ParallaxWaveSamples;

    const float height = 1.5;

    view.xy = view.xy * steps / length(view) * 1.5;

    float waveHeight = getWaves(world) * height;

    for(int i = 0; i < steps; ++i) {
    	world.xz = waveHeight * view.xy - world.xz;

    	waveHeight = getWaves(world) * height;
    }

    return world;
}

#define WavePomMode 0 //[0 1]

vec3 parallax(in vec3 world, in vec3 view) {
	#if WavePomMode == 0
	return getParallax(world, view.xyz);
	#elif WavePomMode == 1
	return getWaveParallax(world, view.xyz);
	#endif
}

vec3 waterNormal(in vec3 world, in vec3 view) {
	const float sampleDist = 0.005;
	#ifdef WavePOM
	vec3 newWorld = parallax(world, normalize(view.xyz));
	#else
	vec3 newWorld = world;
	#endif
	vec2 heightDiffs = vec2(getWaves(vec3(sampleDist,0.0,-sampleDist) + newWorld), getWaves(vec3(-sampleDist,0.0,sampleDist) + newWorld)) - getWaves(vec3(-sampleDist,0.0,-sampleDist) + newWorld);

	vec3 waterNormal = vec3(-2.0 * sampleDist, -2.0 * (sampleDist * sampleDist + sampleDist), 4.0 * sampleDist * sampleDist);
	waterNormal.xy *= heightDiffs;
	waterNormal = normalize(waterNormal);

	return tbn * waterNormal;
}
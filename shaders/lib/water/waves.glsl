#define Octaves 4 //[2 4 8 16 32 64 128] Use this to adjust the amount of octaves.

#define WaveSteepness 0.7 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] Lower causes the waves to be steeper, but will have more issues.
#define WaveAmplitude 0.2 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] Higher will cause the waves to have more amplitude, but will make some POM artifacts more noticable.
#define WaveLength 2.0 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 15.0 20.0 25.0 30.0 35.0] Changes the length/scale of the waves.
#define WaveDirectionX 0.5 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] 
#define WaveDirectionY 0.75 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

float waterNoise(vec2 coord) {
		vec2 floored = floor(coord);
		vec4 samples = textureGather(noisetex, (floored + 0.5) / noiseTextureResolution); // textureGather is slightly offset (at least on nvidia) and this offset can change with driver versions, which is why i floor the coords
		vec4 weights = (coord - floored).xxyy * vec4(1,-1,1,-1) + vec4(0,1,0,1);
		weights *= weights * (-2.0 * weights + 3.0);
		return dot(samples, weights.yxxy * weights.zzww);
}

#include "gerstnerWaves.glsl"

float getWaves(in vec3 position)
{
	const uint numWaves = 4;
	float waveTime = frameTimeCounter * 0.05;

	// Base translation
	vec2 p = -(position.xz + position.y) + waveTime;

	// Scale
	p /= 35.0;

	const float weightArray[numWaves] = float[numWaves] (
		2.0,
		8.0,
		15.0,
		25.0
	);

	vec2 pArray[numWaves] = vec2[numWaves] (
		(p / 1.6) + waveTime * vec2(0.03, 0.07),
		(p / 3.1) + waveTime * vec2(0.08, 0.06),
		(p / 4.7) + waveTime * vec2(0.07, 0.10),
		(p / 8.9) + waveTime * vec2(0.04, 0.02)
	);

	const vec2 scaleArray[numWaves] = vec2[numWaves] (
		vec2(2.0, 1.4),
		vec2(1.7, 0.7),
		vec2(1.0, 1.2),
		vec2(1.0, 0.8)
	);

	vec2 translationArray[numWaves] = vec2[numWaves] (
		vec2(pArray[0].y * 0.0, pArray[0].x * 0.0),
		vec2(pArray[1].y * 0.0, pArray[1].x * 0.0),
		vec2(pArray[2].y * 1.5, pArray[2].x * 1.5),
		vec2(pArray[3].y * 1.5, pArray[3].x * 1.7)
	);

	float waves   = 0.0;
	float weights = 0.0;

	for(int id = 0; id < numWaves; id++) {
		float wave = waterNoise(((pArray[id] * scaleArray[id]) + translationArray[id]) * noiseTextureResolution);

		waves   += wave * weightArray[id];
		weights += weightArray[id];
	}

	waves /= weights;

	waves *= 0.15;
	waves -= 0.15;

	return waves;
}

#define ParallaxWaveSamples 16 //[16 32 64 96 128 256 512 1024] Turn this up to extend the distance of the parallax waves. 
#define PARALLAX_DEPTH 2.75

vec3 parallax_calculateCoordinate(vec3 inPosition, vec3 viewVector) {
	viewVector = normalize(viewVector);
    vec3 position = vec3(inPosition.x, 0.0, inPosition.z);
    viewVector *= vec3(PARALLAX_DEPTH, 1.0, PARALLAX_DEPTH) * 0.05;

    for (int i = 0; i < ParallaxWaveSamples && position.y > getWaves(vec3(position.x, inPosition.y, position.z)); i++, position += viewVector);

    return vec3(position.x, inPosition.y, position.z);
}

vec3 waterNormal(in vec3 world, in vec3 view) {
	const float sampleDist = 0.1;
	#ifdef WavePOM
	vec3 newWorld = parallax_calculateCoordinate(world, view.xzy);
	#else
	vec3 newWorld = world;
	#endif
	vec2 heightDiffs = vec2(getWaves(vec3(sampleDist,0.0,-sampleDist) + newWorld), getWaves(vec3(-sampleDist,0.0,sampleDist) + newWorld)) - getWaves(vec3(-sampleDist,0.0,-sampleDist) + newWorld);
	//heightDiffs *= 1.91;

	vec3 waterNormal = vec3(-2.0 * sampleDist, -2.0 * (sampleDist * sampleDist + sampleDist), 4.0 * sampleDist * sampleDist);
	waterNormal.xy *= heightDiffs;
	waterNormal = normalize(waterNormal);

	return tbn * waterNormal;
}
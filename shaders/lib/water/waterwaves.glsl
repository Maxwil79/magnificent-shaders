#define Octaves 2 //[2 4 6 8 16 32 64 128] Use this to adjust the amount of octaves.

#define WaveSteepness 0.9 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] Lower causes the waves to be steeper, but will have more issues.
#define WaveAmplitude 0.25 //[0.001 0.002 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] Higher will cause the waves to have more amplitude, but will make some POM artifacts more noticable.
#define WaveLength 3.0 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 15.0 20.0 25.0 30.0 35.0] Changes the length/scale of the waves.
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

//#define DetailWaves //Enable this for small scale detail waves at the cost of performance.

#define Speed2 0.08 //[0.001 0.002 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1] Changes the speed of the waves.

float getWaves(in vec3 position)
{
	const uint numWaves = 4;
	float waveTime = frameTimeCounter * Speed2;

	// Base translation
	vec2 p = -(position.xz + position.y) + waveTime;
	vec2 p2 = (position.xz + position.y) + waveTime;

	// Scale
	p /= 64.0;
	p2 /= 9.0 + WaveLength;

	const float weightArray[numWaves] = float[numWaves] (
		1.0,
		8.0,
		15.0,
		0.45
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
		vec2(1.0, 3.8)
	);

	vec2 translationArray[numWaves] = vec2[numWaves] (
		vec2(pArray[0].y * 3.0, pArray[0].x * 0.5),
		vec2(pArray[1].y * 2.0, pArray[1].x * 1.0),
		vec2(pArray[2].y * 1.7, pArray[2].x * 2.3),
		vec2(pArray[3].y * 1.3, pArray[3].x * 0.3)
	);

	const float weightArray2[numWaves] = float[numWaves] (
		1.0,
		8.0,
		15.0,
		0.45
	);

	vec2 pArray2[numWaves] = vec2[numWaves] (
		(p2 / 1.6) + waveTime * vec2(0.03, 0.07),
		(p2 / 3.1) + waveTime * vec2(0.08, 0.06),
		(p2 / 4.7) + waveTime * vec2(0.07, 0.10),
		(p2 / 8.9) + waveTime * vec2(0.04, 0.02)
	);

	const vec2 scaleArray2[numWaves] = vec2[numWaves] (
		vec2(2.0, 1.4),
		vec2(1.7, 0.7),
		vec2(1.0, 1.2),
		vec2(15.0, 30.8)
	);

	vec2 translationArray2[numWaves] = vec2[numWaves] (
		vec2(pArray2[0].y * 0.0, pArray2[0].x * 0.0),
		vec2(pArray2[1].y * 0.0, pArray2[1].x * 0.0),
		vec2(pArray2[2].y * 0.0, pArray2[2].x * 0.0),
		vec2(pArray2[3].y * 0.0, pArray2[3].x * 0.0)
	);

	float waves   = 0.0;
	float weights = 0.0;

    const float f = tau / (2.618);
    float a = cos(f);
    float b = sin(f);

	for(int id = 0; id < numWaves; id++) {
		//float wave = calculateWaveHeight(((pArray[id] * scaleArray[id]) + translationArray[id]) * noiseTextureResolution);
		float wave = waterNoise((rotateNoMat((pArray[id] * scaleArray[id]) + translationArray[id], a, b)) * noiseTextureResolution) * 0.5;
		wave += waterNoise(((pArray2[id] * scaleArray2[id]) + translationArray2[id]) * noiseTextureResolution) * 0.075;
		waves   += wave * weightArray[id];
		weights += weightArray[id];
	}

	waves /= weights;

	waves *= 0.1;
	waves -= 0.1;

	return waves;
}
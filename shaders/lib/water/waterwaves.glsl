#define Octaves 2 //[2 4 6 8 16 32 64 128] Use this to adjust the amount of octaves used by the gerstner waves. Higher means less FPS but more quality.

#define WaveSteepness 1.95
#define WaveAmplitude 0.65
#define WaveLength 5.0 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 15.0 20.0 25.0 30.0 35.0] Changes the length/scale of the waves.
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
	p /= 55.0 + WaveLength;
	p2 /= 12.0 + WaveLength;

	#include "arrays.glsl"

	float waves   = 0.0;
	float weights = 0.0;

    const float f = tau / (2.618);
    float a = cos(f);
    float b = sin(f);

	for(int id = 0; id < numWaves; id++) {
		float wave = waterNoise((rotateNoMat((pArray[id] * scaleArray[id]) + translationArray[id], a, b)) * noiseTextureResolution) * 0.35;
		wave += calculateWaveHeight(((pArray3[id] * scaleArray3[id]) + translationArray3[id]) * noiseTextureResolution);
		waves   += wave * weightArray[id];
		weights += weightArray[id];
	}

	waves /= weights;

	waves *= 0.1;
	waves -= 0.1;

	return waves;
}
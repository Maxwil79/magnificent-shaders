#define Octaves 4 //[2 4 6 8 16 32 64 128] Use this to adjust the amount of octaves used by the gerstner waves. Higher means less FPS but more quality.

#define WaveSteepness 0.85
#define WaveAmplitude 0.025

float waterNoise(vec2 coord) {
		vec2 floored = floor(coord);
		vec4 samples = textureGather(noisetex, (floored + 0.5) / noiseTextureResolution); // textureGather is slightly offset (at least on nvidia) and this offset can change with driver versions, which is why i floor the coords
		vec4 weights = (coord - floored).xxyy * vec4(1,-1,1,-1) + vec4(0,1,0,1);
		weights *= weights * (-2.0 * weights + 3.0);
		return dot(samples, weights.yxxy * weights.zzww);
}

vec2 rotateNoMat(vec2 coord, float a, float b) {
    float ns = b * coord.y + a * coord.x;
    float nc = a * coord.y - b * coord.x;
    return vec2(ns, nc);
}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise2(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float fbm(vec2 x) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);
	// Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
	for (int i = 0; i < 5; ++i) {
		v += a * noise2(x);
		x = rot * x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

//#define DetailWaves //Enable this for small scale detail waves at the cost of performance.

#define Speed2 0.08 //[0.001 0.002 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1] Changes the speed of the waves.

#include "gerstnerWaves.glsl"

float getWaves(in vec3 position)
{
	float waves   = 0.0;

	waves += calculateWaveHeight((position.xz + position.y), 162.5, 0.5, 6.0, 0.025, 0.55, 2);
	waves += calculateWaveHeight((position.xz + position.y), 0.8, 0.15, 0.4, 0.0005, 0.8, 4);
	waves += calculateWaveHeight((position.xz + position.y), 0.2, 0.74, 9.0, 0.03, 0.7, 2);
	waves += calculateWaveHeight((position.xz + position.y), 5.5, 0.5, 4.0, 0.0085, 0.75, 3);
	#ifdef DetailWaves
	waves += fbm(((position.xz + position.y))) * 0.015;
	#endif

	return waves;
}
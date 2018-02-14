#version 420
#line 2

#define WavePOM

/*DRAWBUFFERS: 214*/
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 packedNormals;
layout (location = 2) out vec4 packedData;

in vec4 viewPosition;
in vec4 worldPosition;
in mat3 tbn;
in vec3 vertexNormal;
in vec2 textureCoordinate;
in vec2 lightmapCoordinate;
in float idData;

uniform sampler2D tex;
uniform sampler2D noisetex;

uniform mat4 gbufferModelViewInverse;

uniform float frameTimeCounter;

const float pi  = 3.14159265358979;
const float tau = pi*2.0;

const int noiseTextureResolution = 96;
const int noiseResInverse = 1 / noiseTextureResolution;

#include "lib/encode.glsl"

#define cubicSmooth(x) (x * x) * (3.0 - 2.0 * x)

float waterNoise(vec2 coord) {
		vec2 floored = floor(coord);
		vec4 samples = textureGather(noisetex, floored / noiseTextureResolution); // textureGather is slightly offset (at least on nvidia) and this offset can change with driver versions, which is why i floor the coords
		vec4 weights = (coord - floored).xxyy * vec4(1,-1,1,-1) + vec4(0,1,0,1);
		weights *= weights * (-2.0 * weights + 3.0);
		return dot(samples, weights.yxxy * weights.zzww);
}

float getWaves(in vec3 position)
{
	const uint numWaves = 4;
	float waveTime = frameTimeCounter * 0.05;

	// Base translation
	vec2 p = -(position.xz + position.y) + waveTime;

	// Scale
	p /= 30.0;

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
		float wave = waterNoise(((pArray[id] * scaleArray[id]) + translationArray[id]) * noiseTextureResolution).r;

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
	const float sampleDist = 0.00061;
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

void main() {
    color = texture(tex, textureCoordinate.st);
    vec3 normals = waterNormal(worldPosition.xyz, viewPosition.xyz*tbn);

	bool isWater = false;
    if(abs(idData - 8.5)  < 0.6) isWater = true;
    if(isWater) color = vec4(0.0, 0.0, 0.0, 0.11);

    packedNormals = vec4(packNormal(normalize(normals)), 1.0, 1.0);
    packedData = vec4(encode2x16(sqrt(lightmapCoordinate)), encodeNormal3x16(normals * mat3(gbufferModelViewInverse)), floor(idData + 0.5) / 65535.0, 1.0);
}
#version 420
#line 2
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

#define Octaves 4 //[2 4 8 16 32 64 128] Use this to adjust the amount of octaves.

#define WaveSteepness 0.75 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] Lower causes the waves to be steeper, but will have more issues.
#define WaveAmplitude 0.45 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] Higher will cause the waves to have more amplitude, but will make some POM artifacts more noticable.
#define WaveLength 1.4 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0] Changes the length/scale of the waves.
#define WaveDirectionX 0.5 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] 
#define WaveDirectionY 0.2 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
vec2 rotateNoMat(vec2 coord, float a, float b) {
    float ns = b * coord.y + a * coord.x;
    float nc = a * coord.y - b * coord.x;
    return vec2(ns, nc);
}

vec4 noiseSmooth(vec2 coord) {
    coord = coord * noiseTextureResolution;

	vec2 whole = floor(coord);
	vec2 part  = cubicSmooth(fract(coord));

	coord = (whole + part - 0.5) * noiseResInverse;

	return texture(noisetex, coord);
}

float gernsterWaves(vec2 coord, float time, float waveSteepness, float waveAmplitude, float waveLength, vec2 waveDirection){
	const float g = 19.6;
    
	float k = tau / waveLength;
	float w = sqrt(g * k);

	float x = w * time - k * dot(waveDirection, coord);
	float wave = sin(x) * 0.5 + 0.5;

	float h = waveAmplitude * pow(wave, waveSteepness);

	return h;
}

float calculateWaveHeight(vec2 coord) {
    const int octaves   = Octaves;

    float movement      = frameTimeCounter * 0.3;

    float waveSteepness = WaveSteepness;
    float waveAmplitude = WaveAmplitude;
    float waveLength    = WaveLength;
    vec2  waveDirection = vec2(WaveDirectionX, WaveDirectionY);

    float waves = 0.0;

    const float f = tau * 0.9;
    const float a = cos(f);
    const float b = sin(f);

    for (int i = 0; i < octaves; i++) {
        vec2 noise     = noiseSmooth(coord * 0.005 / sqrt(waveLength)).xy;
        waves         += -gernsterWaves(coord + (noise * 2.0 - 1.0) * sqrt(waveLength), movement, waveSteepness, waveAmplitude * noise.x, waveLength, waveDirection) - noise.y * waveAmplitude;
        waveSteepness *= 1.1;
        waveAmplitude *= 0.6;
        waveLength    *= 0.8;
        waveDirection  = rotateNoMat(waveDirection, a, b);
    }

    return waves;
}

float getWaves(in vec3 position)
{
	return calculateWaveHeight((position.xz + position.y));
}

vec3 waterNormal(in vec3 world) {
	const float sampleDist = 0.00061;
	vec3 newWorld = world;
	vec2 heightDiffs = vec2(getWaves(vec3(sampleDist,0.0,-sampleDist) + newWorld), getWaves(vec3(-sampleDist,0.0,sampleDist) + newWorld)) - getWaves(vec3(-sampleDist,0.0,-sampleDist) + newWorld);
	heightDiffs *= 50.91;

	vec3 waterNormal;
	waterNormal.xy = heightDiffs;
	waterNormal.z  = sqrt(1.0 - dot(waterNormal.xy, waterNormal.xy));

    //waterNormal = mix(vec3(0.0, 0.0, 0.5), waterNormal, dot(normalize(mat3(gbufferModelView) * world), tbn[2]));

	return tbn * waterNormal;
}

void main() {
    color = texture(tex, textureCoordinate.st);

    packedData = vec4(encode2x16(sqrt(lightmapCoordinate)), encodeNormal3x16(vertexNormal * mat3(gbufferModelViewInverse)), floor(idData + 0.5) / 65535.0, 1.0);
}
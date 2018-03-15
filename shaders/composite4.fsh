#version 420

#define BloomRange 4 //[2 4 6 8 16 32 64] Higher means more quality but lower FPS.
#define ApertureBladeCount 5 //[2 3 4 5 6 7 8] Controls the amount of aperture blades.
#define Aperture 0.8 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9] Controls the size of the aperture.
//#define DifractionSpikes //Currently a little awkward.
//#define HighexposureTinting //Enables the high exposure tint.


/*DRAWBUFFERS: 074*/
layout (location = 0) out vec4 color;
layout (location = 1) out float smoothExposure;
layout (location = 2) out vec4 bloomPass;

in vec2 textureCoordinate;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform float frameTimeCounter;
uniform float frameTime;
uniform float aspectRatio;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferModelView;

const bool colortex0MipmapEnabled = true;

const bool colortex7Clear = false;

uniform float viewWidth, viewHeight;
vec2 screenResolution = vec2(viewWidth, viewHeight);

const float pi  = 3.14159265358979;

#include "lib/texture/Bicubic.glsl"
#include "dither.glsl"

vec3 bloom(float LOD, vec2 coordinates) {
	if (coordinates.x < 0.0 || coordinates.x > 1.0 || coordinates.y < 0.0 || coordinates.y > 1.0) return vec3(0.0);

	vec2 resolution = vec2(viewWidth, viewHeight);

	resolution /= exp2(LOD);
	
    const ivec2 range = ivec2(BloomRange);

	vec3 bloomColor = vec3(0.0);
	float totalWeight = 0.0;
	for (int i = -range.x; i <= range.x; i += 1) {
		for (int j = -range.y; j <= range.y; j += 1) {
            vec2 offset = vec2(i, j) * dither2;
            float weight = max(1.0 - length2(offset / range), 0.0);
            offset /= resolution * 1.1;
            weight = pow(weight, 15.0);

            bloomColor += textureLod(colortex0, coordinates + (offset * 1.3), LOD).rgb * weight;
            totalWeight += weight;
		}
	}
    return bloomColor / totalWeight;
}

float linearizeDepth(float depth) {
    return -1.0 / ((depth * 2.0 - 1.0) * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}

vec4 diffractionSpikes (vec4 result) {
    const int spikeSamples = 32;
    const int spikeCount = 8; 
    const float spikeSize = 48.0;
    const float angle = radians(10 + 180.0);

    float finalWeight = 1.0;
    for (int i = 0; i < spikeCount; i++){
        vec2 direction = vec2(cos((2.0 * pi * float(i) / spikeCount) + angle), sin((2.0 * pi * i / spikeCount) + angle)) * dither2;
        for (int j = 0; j < spikeSamples; j++){
            float weight = max(1.0 - pow(float(j) / spikeSamples, 0.00695), 0.0);
            //weight = (1.0 - weight) / (0.00695 * weight * weight);
            result.r += texture(colortex0, textureCoordinate + (direction * 7.0) * j / screenResolution).r * weight;
            result.g += texture(colortex0, textureCoordinate + (direction * 5.0) * j / screenResolution).g * weight;
            result.b += texture(colortex0, textureCoordinate + (direction * 9.0) * j / screenResolution).b * weight;
            finalWeight += weight;
        }
    }
    result /= finalWeight;

    return result;
}

vec3 diffractionSpikes2(vec3 color) {
	const float spikeCount   = 8;
	const float spikeSamples = 32.0;
	const float spikeFalloff = 32.0;
	const float spikeSize    = 0.075 / spikeSamples;
	const float rotation     = radians(10 + 180.0);

	float totalWeight = 1.0;
	for (float i = 0.0; i < 8; i++) {
		float angle = 6.28 * (i / 8) + rotation;
		vec2 direction = vec2(sin(angle), cos(angle)) * spikeSize / vec2(aspectRatio, 1.0);

		for (float j = 1.0; j < spikeSamples; j++) {
			float weight = j / spikeSamples;
			weight = (1.0 - weight) / (spikeFalloff * weight * weight);
			color += texture(colortex0, direction * j + textureCoordinate).rgb * weight;
			totalWeight += weight;
		}
	}
	color /= totalWeight;

	return color;
}

vec3 lumacoeff = vec3(2.5, 2.5, 2.5) / vec3(1.5 / 6.5);

const vec3 lumacoeff_rec709  = vec3(0.2126, 0.7152, 0.0722);

void main() {
    color = texture(colortex0, textureCoordinate);
    float id = texture(colortex4, textureCoordinate.st).b * 65535.0;

    vec3 bloomResult = bloom(0.0, textureCoordinate * 2.0);
    bloomResult += bloom(2.0, (textureCoordinate - vec2(0.51, 0.0)) * 4.0);
    bloomResult += bloom(3.0, (textureCoordinate - vec2(0.51, 0.26)) * 8.0);
    bloomResult += bloom(4.0, (textureCoordinate - vec2(0.645, 0.26)) * 16.0);

    float averageBrightness = dot(textureLod(colortex0, vec2(0.5), log2(max(viewWidth, viewHeight))).rgb, lumacoeff);
    float exposure = clamp(3.0 / averageBrightness, 1.5, 7e2);
	exposure = mix(texture(colortex7, vec2(0.5)).r, exposure, frameTime / (mix(2.5, 0.25, float(exposure < texture(colortex7, vec2(0.5)).r)) + frameTime));

    smoothExposure = exposure;
    bloomPass = vec4(bloomResult, 1.0);

    vec3 highexposuretint = vec3(0.5, 0.8, 1.0);
    vec3 desaturateWeight = vec3(0.8, 0.6, 0.2);
    #ifdef HighexposureTinting
    color.rgb = mix(color.rgb, dot(color.rgb, desaturateWeight) * highexposuretint, clamp(smoothExposure / 6.75e2, 0.0, 1.0));
    bloomPass.rgb = mix(bloomResult.rgb, dot(bloomResult.rgb, desaturateWeight) * highexposuretint, clamp(smoothExposure / 6.75e2, 0.0, 1.0));
    #endif

    vec4 diffraction = vec4(diffractionSpikes2(color.rgb), 1.0);
    #ifdef DifractionSpikes
    color += mix(color, diffraction, 0.2);
    #endif

    color *= smoothExposure;
    bloomPass *= smoothExposure;
}

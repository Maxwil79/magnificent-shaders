#version 450

#define BloomRange 4 //[2 4 6 8 16 32 64] Higher means more quality but lower FPS.
#define ApertureBladeCount 8 //[2 3 4 5 6 7 8] Controls the amount of aperture blades.
#define Aperture 0.8 //[0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8] Controls the size of the aperture.
//#define DifractionSpikes


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

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferModelView;

const bool colortex0MipmapEnabled = true;

const bool colortex7Clear = false;

uniform float viewWidth, viewHeight;
vec2 screenResolution = vec2(viewWidth, viewHeight);

const float pi  = 3.14159265358979;

#include "lib/texture/Bicubic.glsl"

vec3 bloom(float LOD, vec2 coordinates) {
	if (coordinates.x < 0.0 || coordinates.x > 1.0 || coordinates.y < 0.0 || coordinates.y > 1.0) return vec3(0.0);

	vec2 resolution = vec2(viewWidth, viewHeight);

	resolution /= exp2(LOD);
	
    const ivec2 range = ivec2(BloomRange);

	vec3 bloomColor = vec3(0.0);
	float totalWeight = 0.0;
	for (int i = -range.x; i <= range.x; i += 1) {
		for (int j = -range.y; j <= range.y; j += 1) {
            vec2 offset = vec2(i, j) * 1.1;
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

vec3 waterFix(vec2 coord) {
	const vec2 range = vec2(0.0, 0.0);

	vec3 result = vec3(0.0);
	float totalWeight = 0.0;
	for (float i = -range.y; i <= range.y; i++) {
		for (float j = -range.x; j <= range.x; j++) {
			vec2 sampleOffset = vec2(i, j) / vec2(viewWidth, viewHeight);

			float sampleDepth = linearizeDepth(texture(depthtex0, coord + sampleOffset).r);
            float weight = max(1.0 - length(sampleOffset / range), 0.0);
			
			result += textureLod(colortex0, coord + sampleOffset * 0.0, 0.0).rgb * weight;
			totalWeight += weight;
		}
	}
	return result / totalWeight;
}

vec4 diffractionSpikes (vec4 result) {
    const int spikeSamples = 64;
    const int spikeCount = ApertureBladeCount; 
    const float spikeSize = 2.0;
    const float angle = radians(10 + 180.0);

    float finalWeight = 1.0;
    for (int i = 0; i < spikeCount; i++){
        vec2 direction = vec2(cos((2.0 * pi * float(i) / spikeCount) + angle), sin((2.0 * pi * i / spikeCount) + angle));
        for (int j = 0; j < spikeSamples; j++){
            float weight = max(1.0 - pow(float(j) / spikeSamples, 0.00695), 0.0);
            //weight = (1.0 - weight) / (0.00695 * weight * weight);
            result += texture(colortex0, textureCoordinate + (direction * spikeSize) * j / screenResolution) * weight;
            finalWeight += weight;
        }
    }
    result /= finalWeight;

    return pow(result, vec4(6.5));
}

vec3 lumacoeff = vec3(2.5, 2.5, 2.5) / vec3(4.75 / 6.5);

const vec3 lumacoeff_rec709  = vec3(0.2126, 0.7152, 0.0722);

void main() {
    color = texture(colortex0, textureCoordinate);
    float id = texture(colortex4, textureCoordinate.st).b * 65535.0;

    //if(id == 8.0 || id == 9.0 || id == 95.0) color = vec4(waterFix(textureCoordinate.st), 1.0);

    vec3 bloomResult = bloom(0.0, textureCoordinate * 2.0);
    bloomResult += bloom(2.0, (textureCoordinate - vec2(0.51, 0.0)) * 4.0);
    bloomResult += bloom(3.0, (textureCoordinate - vec2(0.51, 0.26)) * 8.0);
    bloomResult += bloom(4.0, (textureCoordinate - vec2(0.645, 0.26)) * 16.0);

    float averageBrightness = dot(textureLod(colortex0, vec2(0.5), log2(max(viewWidth, viewHeight))).rgb, lumacoeff);
    float exposure = clamp(2.35 / averageBrightness, 0.95, 1.55e5);
	exposure = mix(texture(colortex7, vec2(0.5)).r, exposure, frameTime / (mix(2.5, 0.25, float(exposure < texture(colortex7, vec2(0.5)).r)) + frameTime));

    smoothExposure = exposure;
    bloomPass = vec4(bloomResult, 1.0);

    vec3 highexposuretint = vec3(0.3, 0.8, 1.0);
    vec3 desaturateWeight = vec3(0.5, 0.6, 0.2);
    //color.rgb = mix(color.rgb, dot(color.rgb, desaturateWeight) * highexposuretint, clamp(smoothExposure / 1.40e5, 0.0, 1.0));
    //bloomPass.rgb = mix(bloomResult.rgb, dot(bloomResult.rgb, desaturateWeight) * highexposuretint, clamp(smoothExposure / 1.40e5, 0.0, 1.0));

    vec4 diffraction = diffractionSpikes(color);
    #ifdef DifractionSpikes
    color += mix(color, diffraction, 0.2);;
    #endif

    color *= smoothExposure;
    bloomPass *= smoothExposure;
}

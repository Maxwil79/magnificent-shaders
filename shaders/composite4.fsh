#version 400

#define BloomRange 4 //[2 4 6 8 16 32 64] Higher means more quality but lower FPS.

/*DRAWBUFFERS: 074*/
layout (location = 0) out vec4 color;
layout (location = 1) out float smoothExposure;
layout (location = 2) out vec4 bloomPass;

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform float frameTimeCounter;
uniform float frameTime;

const bool colortex0MipmapEnabled = true;

const bool colortex7Clear = false;

uniform float viewWidth, viewHeight;

#define sum3(a) dot(a, vec3(1.0))

vec3 lowlightDesaturate(vec3 color) {
    const vec3 rodResponse = vec3(0.15, 0.50, 0.35); // Should sum to 1

    float desaturated = dot(color, vec3(sum3(rodResponse)));
    color = mix(color, vec3(desaturated) * vec3(0.6, 0.7, 1.20), exp2(-550.0 * desaturated));

    return color;
}

#include "lib/bicubic.glsl"

vec3 bloom(float LOD, vec2 coordinates) {
	if (coordinates.x < 0.0 || coordinates.x > 1.0 || coordinates.y < 0.0 || coordinates.y > 1.0) return vec3(0.0);

	vec2 resolution = vec2(viewWidth, viewHeight);

	resolution /= exp2(LOD);
	
    const ivec2 range = ivec2(BloomRange);

	vec3 bloomColor = vec3(0.0);
	float totalWeight = 0.0;
	for (int i = -range.x; i <= range.x; i += 1) {
		for (int j = -range.y; j <= range.y; j += 1) {
            vec2 offset = vec2(i, j);
            float weight = max(1.0 - length2(offset), 0.0);
            offset /= resolution * 1.1;
            weight = pow(weight, 15.0);

            bloomColor += textureLod(colortex0, coordinates + offset, LOD).rgb * weight;
            totalWeight += weight;
		}
	}
    return bloomColor / totalWeight;
}

void main() {
    color = texture(colortex0, texcoord);

    vec3 bloomResult = bloom(0.0, texcoord * 2.0);
    bloomResult += bloom(2.0, (texcoord - vec2(0.51, 0.0)) * 4.0);
    bloomResult += bloom(3.0, (texcoord - vec2(0.51, 0.26)) * 8.0);
    bloomResult += bloom(4.0, (texcoord - vec2(0.645, 0.26)) * 16.0);

    float averageBrightness = dot(textureLod(colortex0, vec2(0.5), log2(max(viewWidth, viewHeight))).rgb, vec3(1.0 / 0.0746153846));
    float exposure = clamp(3.0 / averageBrightness, 4.5e-4, 2.5e2);
	exposure = mix(texture(colortex7, vec2(0.5)).r, exposure, frameTime / (mix(2.5, 0.25, float(exposure < texture(colortex7, vec2(0.5)).r)) + frameTime));

    smoothExposure = exposure;
    bloomPass = vec4(bloomResult, 1.0);

    color.rgb = lowlightDesaturate(color.rgb);
    bloomPass.rgb = lowlightDesaturate(bloomPass.rgb);

    color *= smoothExposure;
    bloomPass *= smoothExposure;
}

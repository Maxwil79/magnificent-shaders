#version 400


/*DRAWBUFFERS: 07*/
layout (location = 0) out vec4 color;
layout (location = 1) out float smoothExposure;

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
    color = mix(color, vec3(desaturated) * vec3(0.6, 0.7, 1.20), exp2(-600.0 * desaturated));

    return color;
}

void main() {
    color = texture(colortex0, texcoord);

    float averageBrightness = dot(textureLod(colortex0, vec2(0.5), log2(max(viewWidth, viewHeight))).rgb, vec3(1.0 / 0.0346153846));
    float exposure = clamp(3.0 / averageBrightness, 4.5e-4, 7e1);
	exposure = mix(texture(colortex7, vec2(0.5)).r, exposure, frameTime / (mix(2.5, 0.25, float(exposure < texture(colortex7, vec2(0.5)).r)) + frameTime));

    smoothExposure = exposure;

    color.rgb = lowlightDesaturate(color.rgb);

    color *= smoothExposure;
}

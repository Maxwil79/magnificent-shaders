#version 400

#define Bloom

/* DRAWBUFFERS:03 */
layout (location = 0) out vec4 color;
layout (location = 1) out vec3 previousData;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;

//const bool colortex0MipmapEnabled = true;

in vec2 texcoord;

#include "lib/bicubic.glsl"

void main() {
    color = texture(colortex0, texcoord);

    vec4 bloom  = textureBicubic(colortex4, texcoord / 2.0) * 5.0;
    bloom += textureBicubic(colortex4, texcoord / 4.0 + vec2(0.51, 0.0)) * 3.85;
    bloom += textureBicubic(colortex4, texcoord / 8.0 + vec2(0.51, 0.26)) * 2.425;
	bloom /= 5.875;

    float bloomStrength = 0.035;

    previousData = texture(colortex3, texcoord).rgb;

    #ifdef Bloom
    color += bloom * bloomStrength;
    #endif 
}

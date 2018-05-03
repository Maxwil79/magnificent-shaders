#version 400

#define Bloom
#define BloomStrength 0.02 //[0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3]

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 color;

uniform sampler2D colortex0;
uniform sampler2D colortex4;

//const bool colortex0MipmapEnabled = true;

in vec2 texcoord;

#include "lib/bicubic.glsl"

void main() {
    color = texture(colortex0, texcoord);

    vec4 bloom  = textureBicubic(colortex4, texcoord / 2.0) * 5.0;
    bloom += textureBicubic(colortex4, texcoord / 4.0 + vec2(0.51, 0.0)) * 3.85;
    bloom += textureBicubic(colortex4, texcoord / 8.0 + vec2(0.51, 0.26)) * 2.425;
	bloom /= 2.875;

    float bloomStrength = BloomStrength;

    #ifdef Bloom
    color += bloom * bloomStrength;
    #endif 
}

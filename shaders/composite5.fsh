#version 450

#define Bloom
#define BloomStrength 0.06

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 color;

uniform sampler2D colortex0;
uniform sampler2D colortex4;

//const bool colortex0MipmapEnabled = true;

in vec2 textureCoordinate;

#include "lib/texture/Bicubic.glsl"

void main() {
    color = texture(colortex0, textureCoordinate);

    vec4 bloom  = textureBicubic(colortex4, textureCoordinate / 2.0) * 5.0;
    bloom += textureBicubic(colortex4, textureCoordinate / 4.0 + vec2(0.51, 0.0)) * 0.85;
    bloom += textureBicubic(colortex4, textureCoordinate / 8.0 + vec2(0.51, 0.26)) * 0.425;
	bloom /= 2.875;

    float bloomStrength = BloomStrength;

    #ifdef Bloom
    color += bloom * bloomStrength;
    #endif 
}

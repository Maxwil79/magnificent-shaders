#version 400

/* DRAWBUFFERS:0 */

#define getLandMask(x) (x < 1.0)

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

#include "lib/util.glsl"

//ACES tonemap
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.2f;
    float c = 3.43f;
    float d = 0.59f;
    float e = 0.21f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

//This belongs to Jodie
vec3 linearToSRGB(vec3 linear){
    return mix(
        linear * 12.92,
        pow(linear, vec3(1./2.4) ) * 1.055 - .055,
        step( .0031308, linear )
    );
}

void ditherScreen(inout vec3 color) {
    vec3 lestynRGB = vec3(dot(vec2(171.0, 231.0), gl_FragCoord.xy));
         lestynRGB = fract(lestynRGB.rgb / vec3(103.0, 71.0, 97.0));

    color += lestynRGB.rgb / 255.0;
}

vec3 jodieRoboTonemap(vec3 c){
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc = c * inversesqrt( c * c + 1. );
    return mix(c * inversesqrt( l * l + 1. ), tc, tc);
}

void main() {
    vec4 color = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    color.rgb = jodieRoboTonemap(color.rgb);

    color.rgb = linearToSRGB(color.rgb);

    ditherScreen(color.rgb);

    gl_FragData[0] = color;
}
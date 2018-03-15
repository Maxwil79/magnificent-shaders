#version 420

/*DRAWBUFFERS: 01*/

uniform sampler2D tex;

in vec2 uvcoord;

in float id;

in float isWater;

uniform sampler2D noisetex;
uniform float frameTimeCounter;

const float pi  = 3.14159265358979;
const float tau = pi*2.0;

const int noiseTextureResolution = 96;
const int noiseResInverse = 1 / noiseTextureResolution;

#define cubicSmooth(x) (x * x) * (3.0 - 2.0 * x)

layout (location = 0) out vec4 color;
layout (location = 1) out vec4 color1;

#include "lib/water/waterwaves.glsl"

void main() {
    color = texture(tex, uvcoord.st);

    if(isWater == 1.0) color = vec4(1.0);

    color1 = vec4(isWater, 0.0, 0.0, 1.0);
}
#version 450

/*DRAWBUFFERS: 01*/

uniform sampler2D tex;

in vec2 uvcoord;

in float id;

in float isWater;

layout (location = 0) out vec4 color;
layout (location = 1) out vec4 color1;

void main() {
    color = texture(tex, uvcoord.st);

    if(isWater == 1.0) color = vec4(0.0);

    color1 = vec4(isWater, 0.0, 0.0, 1.0);
}
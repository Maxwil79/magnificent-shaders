#version 420

/*DRAWBUFFERS: 0*/
layout (location = 0) out vec4 color;

in vec4 basicColor;

void main() {
    color = basicColor;
}
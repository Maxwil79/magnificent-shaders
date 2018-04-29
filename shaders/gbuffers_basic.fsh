#version 400

/*DRAWBUFFERS: 0*/
layout (location = 0) out vec4 color;

in vec4 basicColor;

in vec2 textureCoordinate;

uniform sampler2D tex;

void main() {
    color = texture(tex, textureCoordinate) * basicColor;
}
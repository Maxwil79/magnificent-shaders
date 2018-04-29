#version 400 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec4 inNormal;
layout (location = 3) in vec4 inColor;
layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;
layout (location = 10) in vec4 mc_Entity;

uniform mat4  gbufferProjection; 

out vec4 basicColor;

out vec2 textureCoordinate;

void main() {
    basicColor = inColor;

    textureCoordinate = inTexCoord.st;

    gl_Position = ftransform();
}
#version 450 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec4 inNormal;
layout (location = 3) in vec4 inColor;
layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;
layout (location = 10) in vec4 mc_Entity;

uniform mat4  gbufferProjection; 

out vec4 basicColor;

void main() {
    basicColor = inColor;
    gl_Position = ftransform();
}
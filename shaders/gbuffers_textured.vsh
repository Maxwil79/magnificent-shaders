#version 420 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec4 inNormal;
layout (location = 3) in vec4 inColor;
layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;
layout (location = 10) in vec4 mc_Entity;

uniform mat4  gbufferProjection; 

out float idData;

out vec2 textureCoordinate;
out vec2 lightmapCoordinate;

out vec3 normals;

out vec4 tint;

void main() {
    tint = inColor;

	idData = mc_Entity.x;

	textureCoordinate = inTexCoord.st;
	lightmapCoordinate = inLightmapCoord.st / 240;
    
    normals = normalize(gl_NormalMatrix * gl_Normal);

    gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);
}
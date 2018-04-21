#version 400 compatibility

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

uniform float frameTimeCounter;
uniform float rainStrength;

uniform sampler2D noisetex;

out vec3 vertexNormal;
out vec2 textureCoordinate;
out vec2 lightmapCoordinate;
out float idData;
out float isWater;

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec3 inNormal;
layout (location = 3) in vec4 inColor;

layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;

layout (location = 10) in vec4 mc_Entity;
layout (location = 12) in vec4 inTangent;

const float pi  = 3.14159265358979;

void main() {

	gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);
    idData = mc_Entity.x;

    vertexNormal = normalize(gl_NormalMatrix * inNormal);

    textureCoordinate = inTexCoord.st;
    lightmapCoordinate = inLightmapCoord.st / 240.0;
    isWater = 1.0;
    if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) isWater = 1.0;
}

#version 450 compatibility

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;

out vec4 viewPosition;
out vec4 worldPosition;
out vec3 world;
out mat3 tbn;
out vec3 vertexNormal;
out vec2 textureCoordinate;
out vec2 lightmapCoordinate;
out float idData;
out float isWater;

//attribute vec4 mc_Entity;
//attribute vec4 at_tangent;

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec3 inNormal;
layout (location = 3) in vec4 inColor;

layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;

layout (location = 10) in vec4 mc_Entity;
layout (location = 12) in vec4 inTangent;

vec4 localSpaceToWorldSpace(in vec4 localSpace) {
	return vec4(localSpace.xyz + cameraPosition, localSpace.w);
}

vec4 viewSpaceToLocalSpace(in vec4 viewSpace) {
	return gbufferModelViewInverse * viewSpace;
}

#define transMAD(mat, v) (mat3(mat) * (v) + (mat)[3].xyz)

void main() {
	gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);
    idData = mc_Entity.x;

	world = transMAD(gbufferModelViewInverse, gl_Position.xyz) + cameraPosition.xyz;

	viewPosition  = gl_ModelViewMatrix * inPosition;
	worldPosition = localSpaceToWorldSpace(viewSpaceToLocalSpace(viewPosition));

    vertexNormal = normalize(gl_NormalMatrix * inNormal);

	tbn = mat3(normalize(gl_NormalMatrix * inTangent.xyz), normalize(cross(gl_NormalMatrix * inTangent.xyz, vertexNormal)) * sign(inTangent.w), vertexNormal);

    textureCoordinate = inTexCoord.st;
    lightmapCoordinate = inLightmapCoord.st / 240.0;
}

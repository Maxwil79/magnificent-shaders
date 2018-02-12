#version 450 compatibility

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

uniform float frameTimeCounter;

uniform sampler2D noisetex;

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

	vec4 v = inPosition;
	float speed = 0.5;
	float t = frameTimeCounter * speed;
	float waveHeight = 0.5;
	float waveWidth = 10.5;
	
	v.y += (
	    sin(waveWidth * inPosition.x + t * 1.3) *
	    cos(waveWidth * inPosition.y + t * 0.9) * waveHeight
    );

	gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);
    idData = mc_Entity.x;

	world = transMAD(gbufferModelViewInverse, gl_Position.xyz) + cameraPosition.xyz;

	viewPosition  = gl_ModelViewMatrix * inPosition;
	worldPosition = localSpaceToWorldSpace(viewSpaceToLocalSpace(viewPosition));

    vertexNormal = normalize(gl_NormalMatrix * inNormal);

	tbn = mat3(normalize(gl_NormalMatrix * inTangent.xyz), normalize(cross(gl_NormalMatrix * inTangent.xyz, vertexNormal)) * sign(inTangent.w), vertexNormal);

    textureCoordinate = inTexCoord.st;
    lightmapCoordinate = inLightmapCoord.st / 240.0;
    isWater = 1.0;
    if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) isWater = 1.0;
}

#version 420 compatibility

//#define WavingWater //WiP

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

uniform float frameTimeCounter;
uniform float rainStrength;

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

const float pi  = 3.14159265358979;

#define transMAD(mat, v) (mat3(mat) * (v) + (mat)[3].xyz)

void main() {

	vec4 v = (gl_ModelViewMatrix * inPosition);
	vec4 v2 = gbufferModelViewInverse * v;
	float speed = 0.5;
	float t = frameTimeCounter * speed;
	float waveHeight = 0.075;
	float waveWidth = 10.5;

	vec3 w = v2.xyz + cameraPosition;

	#ifdef WavingWater
	if(mc_Entity.x != 79.0 && mc_Entity.x != 95.0 && mc_Entity.x != 160.0 && mc_Entity.x != 165.0) {
                v.y += waveHeight * sin(4 * pi * (t + w.x / waveWidth  + w.x / waveWidth));
                v.y += waveHeight * sin(2 * pi * (t + w.z / waveWidth + w.z / waveWidth));
	}
	#endif

	gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);
	gl_Position += gbufferProjection * v;
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

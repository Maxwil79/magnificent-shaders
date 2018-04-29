#version 400 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec4 inNormal;
layout (location = 3) in vec4 inColor;
layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;
layout (location = 10) in vec4 mc_Entity;
layout (location = 12) in vec4 inTangent;

out float idData;

out vec2 textureCoordinate;
out vec2 lightmapCoordinate;

out vec3 normal;
out vec3 viewPosition;
out vec3 worldPosition;

out mat3 tbn;

out vec4 tint;

uniform mat4 gbufferProjection;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;

void main() {
    gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);

    tint = inColor;
    normal = normalize(gl_NormalMatrix * inNormal.xyz);
    textureCoordinate = inTexCoord.st;
    lightmapCoordinate = inLightmapCoord.st / 240.0;
    idData = mc_Entity.x;

	viewPosition  = (gl_ModelViewMatrix * inPosition).xyz;
	worldPosition = (gbufferModelViewInverse * gl_ModelViewMatrix * inPosition).xyz + cameraPosition;

	tbn = mat3(normalize(gl_NormalMatrix * inTangent.xyz), normalize(gl_NormalMatrix * cross(inTangent.xyz, inNormal.xyz) * sign(inTangent.w)), normalize(gl_NormalMatrix * inNormal.xyz));
}
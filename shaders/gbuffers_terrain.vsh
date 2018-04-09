#version 420 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec4 inNormal;
layout (location = 3) in vec4 inColor;
layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;
layout (location = 10) in vec4 mc_Entity;
layout (location = 11) in vec2 quadMidUV;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

uniform float frameTimeCounter;

out float idData;

out vec2 textureCoordinate;
out vec2 lightmapCoordinate;

out vec3 normals;

out vec4 tint;

const float pi  = 3.14159265358979;

void main() {
    tint = inColor;

	idData = mc_Entity.x;

	textureCoordinate = inTexCoord.st;
	lightmapCoordinate = inLightmapCoord.st / 240;
    
    normals = normalize(gl_NormalMatrix * gl_Normal);

	vec4 v = (gl_ModelViewMatrix * inPosition);
	vec4 v2 = gbufferModelViewInverse * v;
	float speed = 0.25;
	float t = frameTimeCounter * speed;
	float waveHeight = 0.045;
	float waveWidth = 6.5;

	vec3 w = v2.xyz + cameraPosition;

	if(mc_Entity.x == 18.0 || mc_Entity.x == 161.0) {
                v.y += waveHeight * sin(4 * pi * (t + w.x / waveWidth  + w.z / waveWidth));
                v.y += waveHeight * sin(2 * pi * (t + w.x / waveWidth + w.z / waveWidth));
	}

	gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);
	gl_Position += gbufferProjection * v;
}
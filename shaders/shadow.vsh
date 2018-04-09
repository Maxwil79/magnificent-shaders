#version 420 compatibility

#define PlayerShadow //Disable this ti disable the player shadow.

layout (location = 0) in vec4 inPosition;
layout (location = 8) in vec4 inTexCoord;
layout (location = 10) in vec4 mc_Entity;

uniform mat4 shadowProjection, shadowModelView;
uniform mat4 shadowProjectionInverse, shadowModelViewInverse;

uniform int entityId;

out vec2 uvcoord;

out float id;

out float isWater;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;
const float pi  = 3.14159265358979;

#include "lib/light/distortion.glsl"

void main() {
	vec4 v = (gl_ModelViewMatrix * inPosition);
	vec4 v2 = shadowModelViewInverse * v;
	float speed = 0.25;
	float t = frameTimeCounter * speed;
	float waveHeight = 0.045;
	float waveWidth = 6.5;

	vec3 w = v2.xyz + cameraPosition;

	if(mc_Entity.x == 18.0 || mc_Entity.x == 161.0) {
                v.y += waveHeight * sin(4 * pi * (t + w.x / waveWidth  + w.z / waveWidth));
                v.y += waveHeight * sin(2 * pi * (t + w.x / waveWidth + w.z / waveWidth));
	}

	gl_Position = shadowProjection * v;

    gl_Position.xy /= ShadowDistortion(gl_Position.xy);
    gl_Position.z /= 6.0;

    id = mc_Entity.x;

    if (mc_Entity.x == 51) {
    // Is a fire vertex
    gl_Position = vec4(0.0);
    }

    #ifndef PlayerShadow
    if (mc_Entity.x == 0 && entityId == -1) {
    // Is a player vertex
    gl_Position = vec4(0.0);
    }
    #endif

    isWater = 0.0;
    if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) isWater = 1.0;

    uvcoord = (gl_TextureMatrix[0] * inTexCoord).xy;
}
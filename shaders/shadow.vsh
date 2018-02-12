#version 450 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 8) in vec4 inTexCoord;
layout (location = 10) in vec4 mc_Entity;

uniform mat4  shadowProjection; 

out vec2 uvcoord;

out float id;

out float isWater;

#include "lib/light/distortion.glsl"

void main() {
	gl_Position = shadowProjection * gl_ModelViewMatrix * inPosition;

    gl_Position.xy /= ShadowDistortion(gl_Position.xy);
    gl_Position.z /= 6.0;

    id = mc_Entity.x;

    if (mc_Entity.x == 51) {
    // Is a fire vertex
    gl_Position = vec4(0.0);
    }

    isWater = 0.0;
    if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) isWater = 1.0;

    uvcoord = (gl_TextureMatrix[0] * inTexCoord).xy;
}
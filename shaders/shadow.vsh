#version 120

#define Entity_Shadows

varying vec2 uvcoord;
varying float isWater;

uniform int entityId;

attribute vec4 mc_Entity;

uniform mat4 shadowProjection, shadowModelView;
uniform mat4 shadowProjectionInverse, shadowModelViewInverse;

#include "lib/distortion.glsl"

mat4 newShadowModelView = mat4(
    1, 0, 0, shadowModelView[0].w,
    0, 0, 1, shadowModelView[1].w,
    0, 1, 0, shadowModelView[2].w,
    shadowModelView[3]
);

void main() {
    gl_Position = ftransform();

    gl_Position = gl_ModelViewMatrix * gl_Vertex;
    //gl_Position = newShadowModelView * shadowModelViewInverse * gl_Position;
    gl_Position = shadowProjection * gl_Position;

    gl_Position.xy /= ShadowDistortion(gl_Position.xy);
    gl_Position.z /= 6.0;

    #ifndef Entity_Shadows
    if (mc_Entity.x == 0 && entityId == -1) {
    // Is a player vertex
    gl_Position = vec4(0.0);
    }

    if (mc_Entity.x == 0) {
    // Is a fire vertex
    gl_Position = vec4(0.0);
    }
    #endif

    uvcoord = gl_MultiTexCoord0.st;

    isWater = 0.0;
    if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) isWater = 1.0;
}
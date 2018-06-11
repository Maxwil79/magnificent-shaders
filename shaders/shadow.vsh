#version 120

#define Entity_Shadows

varying mat3 tbn;
varying vec4 viewPosition;
varying vec4 worldPosition;
varying vec3 light;
varying vec2 uvcoord;
varying float isWater;
varying float isPortal;

uniform int entityId;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

uniform mat4 shadowProjection, shadowModelView;
uniform mat4 shadowProjectionInverse, shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;

#include "lib/distortion.glsl"

mat4 newShadowModelView = mat4(
    1, 0, 0, shadowModelView[0].w,
    0, 0, 1, shadowModelView[1].w,
    0, 1, 0, shadowModelView[2].w,
    shadowModelView[3]
);

vec4 localSpaceToWorldSpace(in vec4 localSpace) {
	return vec4(localSpace.xyz + cameraPosition, localSpace.w);
}

vec4 viewSpaceToLocalSpace(in vec4 viewSpace) {
	return shadowModelViewInverse * viewSpace;
}

#define transMAD(mat, v) (mat3(mat) * (v) + (mat)[3].xyz)

#define diagonal2(mat) vec2((mat)[0].x, (mat)[1].y)
#define diagonal3(mat) vec3(diagonal2(mat), (mat)[2].z)
#define diagonal4(mat) vec4(diagonal3(mat), (mat)[2].w)

void main() {
	gl_Position.xyz = transMAD(shadowModelViewInverse, transMAD(gl_ModelViewMatrix, gl_Vertex.xyz));
	gl_Position = transMAD(shadowModelView, gl_Position.xyz).xyzz * diagonal4(gl_ProjectionMatrix) + vec4(0, 0, gl_ProjectionMatrix[3].zw);

    gl_Position.xy /= ShadowDistortion(gl_Position.xy);
    gl_Position.z /= 4.0;

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

    light = mat3(gbufferModelViewInverse) * normalize(sunPosition);

	viewPosition  = gl_ModelViewMatrix * gl_Vertex;
	worldPosition = localSpaceToWorldSpace(viewSpaceToLocalSpace(viewPosition));

    uvcoord = gl_MultiTexCoord0.st;

    tbn = mat3(normalize(gl_NormalMatrix * at_tangent.xyz), normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * sign(at_tangent.w)), normalize(gl_NormalMatrix * gl_Normal.xyz));

    isWater = 0.0;
    if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) isWater = 1.0;
    isPortal = 0.0;
    if(mc_Entity.x == 90.0) isPortal = 1.0;
}
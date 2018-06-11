#version 400

//#define SHADOW

/*DRAWBUFFERS: 245*/
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 packedData;
layout (location = 2) out vec4 packedSpecNormal;

in vec3 viewPosition;
in vec3 worldPosition;
in vec3 vertexNormal;
in mat3 tbn;
in vec2 textureCoordinate;
in vec2 lightmapCoordinate;
in float idData;

uniform sampler2D tex;
uniform sampler2D noisetex;
uniform sampler2D normals;
uniform sampler2D colortex0;
uniform sampler2D colortex6;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;
uniform mat4 gbufferProjection, gbufferModelView;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;

const float pi  = 3.14159265358979;
const float tau = pi*2.0;

#include "lib/encoding/encode.glsl"

#include "lib/util.glsl"

#include "lib/water.glsl"

#define Continuum_2

void main() {

	bool isWater = false;
    bool isGlass = false;
    bool isIce = false;
    if(abs(idData - 8.5)  < 0.6) isWater = true;
    if(abs(idData - 95.0) < 0.6 || abs(idData - 160.0) < 0.6) isGlass = true;
    if(abs(idData - 79.0) < 0.6) isIce = true;

    vec3 normal = vertexNormal;
    if(isIce) {
        vec3 normalMap = texture(normals, textureCoordinate.st).rgb;
        normalMap = normalMap * 2.0 - 1.0;
        normalMap = normalize(tbn * normalMap);
        normal = normalMap;
    }
    if(isWater) normal = tbn * waterNormals(worldPosition, (viewPosition*tbn).xzy, 0.01);

    #ifdef Continuum_2
    float reflectance = 0.0;
    if(isIce) reflectance = 0.85;
    if(isWater) reflectance = 0.2;
    if(isGlass) reflectance = 0.7;
    #else
    float reflectance = 0.0;
    if(isIce) reflectance = 0.5;
    if(isWater) reflectance = 0.2;
    if(isGlass) reflectance = 0.1;
    #endif

    if(!isWater) {
        color = vec4(texture(tex, textureCoordinate.st).rgb, reflectance);
    }

    if(abs(idData - 90.0) < 0.6) color = texture(tex, textureCoordinate.st);

    if(isWater) color = vec4(1.0, 1.0, 1.0, 0.11);

    vec4 spec = vec4(reflectance, 0.0, 0.9, 1.0);

    packedSpecNormal = vec4(encode4x16(spec), packNormal(normalize(normal)), 1.0);
    packedData = vec4(encode2x16(sqrt(lightmapCoordinate)), encodeNormal3x16(mat3(gbufferModelViewInverse) * normal), floor(idData + 0.5) / 65535.0, 1.0);
}
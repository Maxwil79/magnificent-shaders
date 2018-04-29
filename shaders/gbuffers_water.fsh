#version 400

/*DRAWBUFFERS: 214*/
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 packedNormals;
layout (location = 2) out vec4 packedData;

in vec3 viewPosition;
in vec3 worldPosition;
in vec3 vertexNormal;
in mat3 tbn;
in vec2 textureCoordinate;
in vec2 lightmapCoordinate;
in float idData;

uniform sampler2D tex;
uniform sampler2D noisetex;
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

void main() {

    color = texture(tex, textureCoordinate.st);

	bool isWater = false;
    if(abs(idData - 8.5)  < 0.6) isWater = true;
    if(isWater) color = vec4(0.0, 0.475, 0.5, 0.15);

    vec3 normals = vertexNormal;
    if(isWater) normals = tbn * waterNormals(worldPosition, viewPosition*tbn);

    packedNormals = vec4(packNormal(normalize(normals)), 1.0, 1.0);
    packedData = vec4(encode2x16(sqrt(lightmapCoordinate)), encodeNormal3x16(mat3(gbufferModelViewInverse) * normals), floor(idData + 0.5) / 65535.0, 1.0);
}
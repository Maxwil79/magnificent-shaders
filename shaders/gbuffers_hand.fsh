#version 400

/* DRAWBUFFERS:041 */

layout (location = 0) out vec4 color;
layout (location = 1) out vec4 packedData;
layout (location = 2) out vec4 packedNormal;

in float idData;

in vec2 textureCoordinate;
in vec2 lightmapCoordinate;

in vec3 normal;
in vec3 worldPosition;
in vec3 viewPosition;

in mat3 tbn;

in vec4 tint;

uniform sampler2D tex;
uniform sampler2D normals;
uniform sampler2D specular;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

#include "lib/encoding/encode.glsl"

void main() {
    color = texture(tex, textureCoordinate.st) * tint;
    vec3 normalMap = texture(normals, textureCoordinate.st).rgb;
    normalMap = normalMap * 2.0 - 1.0;
    normalMap = normalize(tbn * normalMap);

    packedNormal = vec4(packNormal(normalMap), 1.0, 1.0);
    packedData = vec4(encode2x16(lightmapCoordinate), encodeNormal3x16(mat3(gbufferModelViewInverse) * normalMap), floor(idData + 0.5) / 65535.0, 1.0);
}
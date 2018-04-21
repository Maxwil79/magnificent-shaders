#version 400

/* DRAWBUFFERS:04 */

layout (location = 0) out vec4 color;
layout (location = 1) out vec4 packedData;

in float idData;

in vec2 textureCoordinate;
in vec2 lightmapCoordinate;

in vec3 normal;

uniform sampler2D tex;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

#include "lib/encoding/encode.glsl"

void main() {
    color = texture(tex, textureCoordinate);
    packedData = vec4(encode2x16(lightmapCoordinate), encodeNormal3x16(mat3(gbufferModelViewInverse) * normal), floor(idData + 0.5) / 65535.0, 1.0);
}
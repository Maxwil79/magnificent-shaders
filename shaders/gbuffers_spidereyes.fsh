#version 400

/* DRAWBUFFERS:54 */

layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 packedData;

in vec4 color;
in vec2 uvcoord;
in vec2 lmcoord;
in vec3 normal;
in vec4 metadata;

uniform sampler2D tex;
uniform sampler2D lightmap;
uniform sampler2D specular;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

#include "lib/encoding/encode.glsl"

void main() {
    colorOut = texture(tex, uvcoord);
    packedData = vec4(encode2x16(lmcoord), encodeNormal3x16(mat3(gbufferModelViewInverse) * normal), floor(metadata.x + 0.5) / 65535.0, 1.0);
}
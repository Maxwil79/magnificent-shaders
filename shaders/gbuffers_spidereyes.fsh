#version 400

//This file should probably be done a different way, but this works for now.

/* DRAWBUFFERS:041 */

layout (location = 0) out vec4 color;
layout (location = 1) out vec4 packedData;

in vec2 textureCoordinate;
in vec2 lightmapCoordinate;

uniform sampler2D tex;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

#include "lib/encoding/encode.glsl"

float spiderEnderEyes = 0.0;

void main() {
    color = texture(tex, textureCoordinate.st);

    spiderEnderEyes = 1.0;

    packedData = vec4(encode2x16(lightmapCoordinate), spiderEnderEyes, 1.0, 1.0);
}
#version 420

/*DRAWBUFFERS: 04*/
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 packedData;
//layout (location = 2) out vec4 normal;

in float idData;

in vec2 lightmapCoordinate;
in vec2 textureCoordinate;

in vec3 normals;

in vec4 tint;

uniform sampler2D tex;
uniform sampler2D specular;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

#include "lib/encode.glsl"

void main() {
    color = texture(tex, textureCoordinate.st) * tint;
    packedData = vec4(encode2x16(lightmapCoordinate), encodeNormal3x16(mat3(gbufferModelViewInverse) * normals), floor(idData + 0.5) / 65535.0, 1.0);
    //normal = vec4(normals * 0.5 + 0.5, 1.0);
}
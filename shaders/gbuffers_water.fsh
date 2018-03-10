#version 420
#line 2

#define WavePOM

/*DRAWBUFFERS: 214*/
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 packedNormals;
layout (location = 2) out vec4 packedData;

in vec4 viewPosition;
in vec4 worldPosition;
in mat3 tbn;
in vec3 vertexNormal;
in vec2 textureCoordinate;
in vec2 lightmapCoordinate;
in float idData;

uniform sampler2D tex;
uniform sampler2D noisetex;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

uniform float frameTimeCounter;

const float pi  = 3.14159265358979;
const float tau = pi*2.0;

const int noiseTextureResolution = 96;
const int noiseResInverse = 1 / noiseTextureResolution;

#include "lib/encode.glsl"

#define cubicSmooth(x) (x * x) * (3.0 - 2.0 * x)

#include "lib/water/waves.glsl"

void main() {
    color = texture(tex, textureCoordinate.st);

	bool isWater = false;
    if(abs(idData - 8.5)  < 0.6) isWater = true;
    if(isWater) color = vec4(0.0, 0.0, 0.0, 0.11);

    vec3 normals = vertexNormal;
    if(isWater) normals = waterNormal(worldPosition.xyz, viewPosition.xyz*tbn);

    packedNormals = vec4(packNormal(normalize(normals)), 1.0, 1.0);
    packedData = vec4(encode2x16(sqrt(lightmapCoordinate)), encodeNormal3x16(normals * mat3(gbufferModelViewInverse)), floor(idData + 0.5) / 65535.0, 1.0);
}
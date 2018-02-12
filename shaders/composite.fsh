#version 450

#define ShadowType 0 //[0 1]

/*DRAWBUFFERS: 0*/
layout (location = 0) out vec4 color;

/*
const int colortex0Format = RGBA32F;
const int colortex1Format = RGBA32F;
const int colortex2Format = RGBA32F;
const int colortex3Format = RGBA32F;
const int colortex4Format = RGBA32F;
const int colortex7Format = RGB32F;
*/

const float pi  = 3.14159265358979;

const int   shadowMapResolution      = 1024; //[512 1024 2048 4096 8192]
const float sunPathRotation = -35.0;

in vec2 textureCoordinate;
in vec3 lightVector;
in vec3 worldLightVector;
in vec3 sunVector;
in vec3 moonVector;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;

uniform float far;
uniform float viewHeight, viewWidth;
uniform float frameTimeCounter;

uniform mat4 shadowProjection, shadowModelView;
uniform mat4 shadowProjectionInverse, shadowModelViewInverse;
uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferModelView;

const float eyeBrightnessHalflife = 0.93;

float square (float x) { return x * x; }
vec2  square (vec2  x) { return x * x; }
vec3  square (vec3  x) { return x * x; }
vec4  square (vec4  x) { return x * x; }

#define inverseSquare(x) (1.0 / square(x))

vec3 blackbody(float t){
    // http://en.wikipedia.org/wiki/Planckian_locus

    vec4 vx = vec4(-0.2661239e9,-0.2343580e6,0.8776956e3,0.179910);
    vec4 vy = vec4(-1.1063814,-1.34811020,2.18555832,-0.20219683);
    float it = 1./t;
    float it2= it*it;
    float x = dot(vx,vec4(it*it2,it2,it,1.));
    float x2 = x*x;
    float y = dot(vy,vec4(x*x2,x2,x,1.));
    float z = 1. - x - y;
    
    // http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
    mat3 xyzToSrgb = mat3(
         3.2404542,-1.5371385,-0.4985314,
        -0.9692660, 1.8760108, 0.0415560,
         0.0556434,-0.2040259, 1.0572252
    );

    vec3 srgb = vec3(x/y,1.,z/y) * xyzToSrgb;
    return max(srgb,0.);
}

#include "dither.glsl"

#include "lib/decode.glsl"

#include "lib/raysphereIntersections/raysphereIntersection.glsl"
#include "lib/atmosphere/physicalAtmosphere.glsl"
#include "lib/atmosphere/physicalSun.glsl"
#include "lib/atmosphere/physicalMoon.glsl"

#include "lib/util.glsl"

#include "lib/rays/rayTracers.glsl"

const vec2[36] offset = vec2[36](
        vec2(-0.90167680,  0.34867350),
        vec2(-0.98685560, -0.03261871),
        vec2(-0.67581730,  0.60829530),
        vec2(-0.47958790,  0.23570540),
        vec2(-0.45314310,  0.48728980),
        vec2(-0.30706600, -0.15843290),
        vec2(-0.09606075, -0.01807100),
        vec2(-0.60807480,  0.01524314),
        vec2(-0.02638345,  0.27449020),
        vec2(-0.17485240,  0.49767420),
        vec2( 0.08868586, -0.19452260),
        vec2( 0.18764890,  0.45603400),
        vec2( 0.39509670,  0.07532994),
        vec2(-0.14323580,  0.75790890),
        vec2(-0.52281310, -0.28745570),
        vec2(-0.78102060, -0.44097930),
        vec2(-0.40987180, -0.51410110),
        vec2(-0.12428560, -0.78665660),
        vec2(-0.52554520, -0.80657600),
        vec2(-0.01482044, -0.48689910),
        vec2(-0.45758520,  0.83156060),
        vec2( 0.18829080,  0.71168610),
        vec2( 0.23589650, -0.95054530),
        vec2( 0.26197550, -0.61955050),
        vec2( 0.47952230,  0.32172530),
        vec2( 0.52478220,  0.61679990),
        vec2( 0.85708400,  0.47555550),
        vec2( 0.75702890,  0.08125463),
        vec2( 0.48267020,  0.86368290),
        vec2( 0.33045960, -0.31044460),
        vec2( 0.59658700, -0.35501270),
        vec2( 0.69684450, -0.61393110),
        vec2( 0.88014110, -0.41306840),
        vec2( 0.07468465,  0.99449370),
        vec2( 0.92697510, -0.10826900),
        vec2( 0.45471010, -0.78973980)
);

vec3 blockLightColor = 0.0005 * blackbody(3450);

vec3 ScreenSpaceShadows() {
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture2D(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;

    vec3 lighting = vec3(0.0);

    vec4 hitPosition;
    if (!raytraceIntersection(viewPosition, lightVector, hitPosition, 64.0, 0.0, 0.0025, 1.0, 0.05)) {
        return vec3(1.0);
    }

    return vec3(0.0);
}

float lerp(float v0, float v1, float t) {
  return (1 - t) * v0 + t * v1;
}

#include "lib/light/shading.glsl"

#define getLandMask(x) (x < 1.0)

void main() {
    color = texture(colortex0, textureCoordinate.st);
    vec4 transparents = texture(colortex2, textureCoordinate.st);
    float id = texture(colortex4, textureCoordinate.st).b * 65535.0;

    transparents.rgb = pow(transparents.rgb, vec3(2.2));

    float depth = texture(depthtex0, textureCoordinate.st).r;

    vec4 view2 = vec4(vec3(textureCoordinate.st, depth) * 2.0 - 1.0, 1.0);
    view2 = gbufferProjectionInverse * view2;
    view2 /= view2.w;
    vec4 world = gbufferModelViewInverse * view2;
    world /= world.w;

    float shadows;

    color.rgb = mix(color.rgb, getShading(transparents.rgb, world.xyz, id, shadows, normalize(view2.xyz)), transparents.a);

    color.a = shadows;
}
